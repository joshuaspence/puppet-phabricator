require_relative '../spec_helper_acceptance'

RSpec.describe 'phabricator' do
  pp = <<-EOS
    include apt

    Apt::Ppa {
      package_manage => true,
    }

    # Ensure that `apt-get update` is executed before any packages are
    # installed. See https://github.com/puppetlabs/puppetlabs-apt/#adding-new-sources-or-ppas.
    Class['apt::update'] -> Package <| title != 'apt-transport-https' and title != 'ca-certificates' and title != 'software-properties-common' |>

    class { 'php::globals':
      php_version => '7.1',
    }

    class { 'php':
      manage_repos => true,
      fpm          => false,
      dev          => false,
      composer     => false,
      pear         => false,
    }

    class { 'phabricator':
      config_hash => {
        'mysql.host' => 'localhost',
        'mysql.user' => 'root',
        'mysql.pass' => 'root',
      },

      storage_upgrade          => true,
      storage_upgrade_user     => 'root',
      storage_upgrade_password => 'root',

      manage_diffusion => true,
    }
  EOS

  # TODO: Move this to a shared example.
  it 'applies with no errors' do
    apply_manifest(pp, catch_failures: true)
  end

  it 'applies a second time without changes' do
    apply_manifest(pp, catch_changes: true)
  end

  # Detect unsupported PHP versions.
  #
  # Phabricator doesn't support PHP 7.0, although it _does_ support PHP 7.1
  # (which implements [async signals](https://wiki.php.net/rfc/async_signals)).
  # See https://secure.phabricator.com/T9640, https://secure.phabricator.com/T11270
  # and https://secure.phabricator.com/T12101.
  #
  # TODO: If https://secure.phabricator.com/T2383 is resolved then we should be
  # able to run `./bin/config check` instead.
  context command('php --version') do
    its(:exit_status) { is_expected.to be_zero }
    its(:stdout) { is_expected.not_to start_with('PHP 7.0.'), 'Unsupported PHP version.' }
  end

  describe 'phabricator::config' do
    context group('phabricator') do
      it { is_expected.to exist }
    end

    context user('phd') do
      it { is_expected.to exist }
      it { is_expected.to belong_to_primary_group('phabricator') }
      it { is_expected.to have_home_directory('/run/phabricator') }
      it { is_expected.to have_login_shell('/usr/sbin/nologin') }
    end

    context user('diffusion') do
      it { is_expected.to exist }
      it { is_expected.to belong_to_primary_group('phabricator') }
      it { is_expected.to have_home_directory('/var/repo') }
      it { is_expected.to have_login_shell('/bin/sh') }
    end

    context command('sudo --login --user=phd') do
      its(:exit_status) { is_expected.not_to be_zero }
      its(:stdout) { is_expected.to contain('This account is currently not available.') }
    end

    context file('/var/log/phabricator') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by('root') }
      it { is_expected.to be_grouped_into('phabricator') }
      it { is_expected.to be_mode(775) }
    end

    context file('/run/phabricator') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by('root') }
      it { is_expected.to be_grouped_into('phabricator') }
      it { is_expected.to be_mode(775) }
    end

    context file('/var/repo') do
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by('phd') }
      it { is_expected.to be_grouped_into('phabricator') }
      it { is_expected.to be_mode(750) }
    end

    context file('/usr/local/src/phabricator/conf/local/local.json') do
      it { is_expected.to be_file }
      it { is_expected.to be_owned_by('root') }
      it { is_expected.to be_grouped_into('phabricator') }
      it { is_expected.to be_mode(640) }

      its(:content_as_json) do
        is_expected.to eq(
          'diffusion.ssh-user' => 'diffusion',
          'log.access.path' => '/var/log/phabricator/access.log',
          'log.ssh.path' => '/var/log/phabricator/ssh.log',
          'mysql.host' => 'localhost',
          'mysql.user' => 'root',
          'mysql.pass' => 'root',
          'phd.log-directory' => '/var/log/phabricator',
          'phd.pid-directory' => '/run/phabricator',
          'phd.user' => 'phd',
          'repository.default-local-path' => '/var/repo',
        )
      end
    end

    context command('/usr/local/src/phabricator/bin/config get mysql.host') do
      its(:stdout_as_json) do
        is_expected.to include(
          'config' => [
            {
              'key' => 'mysql.host',
              'source' => 'local',
              'value' => 'localhost',
              'status' => 'set',
              'errorInfo' => nil,
            },
            {
              'key' => 'mysql.host',
              'source' => 'database',
              'value' => nil,
              'status' => 'unset',
              'errorInfo' => nil,
            },
          ],
        )
      end
    end

    context command('/usr/local/src/phabricator/bin/storage status') do
      its(:exit_status) { is_expected.to be_zero }
      its(:stdout) { is_expected.not_to contain('Not Applied') }
    end

    context command('/usr/local/src/phabricator/bin/storage databases') do
      its(:exit_status) { is_expected.to be_zero }

      its(:stdout) { is_expected.to contain('phabricator_cache') }
      its(:stdout) { is_expected.to contain('phabricator_meta_data') }
      its(:stdout) { is_expected.to contain('phabricator_policy') }
      its(:stdout) { is_expected.to contain('phabricator_system') }
    end

    sudo_commands = {
      'diffusion' => [
        '/usr/bin/git-receive-pack',
        '/usr/bin/git-upload-pack',
        '/usr/bin/ssh',
      ],

      'www-data' => [
        '/usr/bin/ssh',
        '/usr/lib/git-core/git-http-backend',
      ],
    }

    sudo_commands.each do |user, commands|
      commands.each do |command|
        context command("sudo --list --other-user=#{user} --user=phd #{command}") do
          its(:exit_status) { is_expected.to be_zero }
        end
      end
    end
  end

  describe 'phabricator::install' do
    context command('git --version') do
      its(:exit_status) { is_expected.to be_zero }
    end

    context command('php --version') do
      its(:exit_status) { is_expected.to be_zero }
    end

    context command('php --modules') do
      its(:exit_status) { is_expected.to be_zero }
      its(:stderr) { is_expected.to be_empty }

      its(:stdout) { is_expected.to match(/^apcu$/) }
      its(:stdout) { is_expected.to match(/^curl$/) }
      its(:stdout) { is_expected.to match(/^gd$/) }
      its(:stdout) { is_expected.to match(/^mbstring$/) }
      its(:stdout) { is_expected.to match(/^mysqli$/) }

      # These PHP extensions are not explicitly installed by this module,
      # but are expected to be available.
      its(:stdout) { is_expected.to match(/^fileinfo$/) }
      its(:stdout) { is_expected.to match(/^pcntl$/) }
      its(:stdout) { is_expected.to match(/^posix$/) }
    end

    %w[arcanist libphutil phabricator].each do |repo|
      repo_path = "/usr/local/src/#{repo}"
      repo_url = "https://github.com/phacility/#{repo}.git"

      context file(repo_path) do
        it { is_expected.to be_directory }
        it { is_expected.to be_owned_by('root') }
        it { is_expected.to be_grouped_into('root') }
        it { is_expected.to be_mode(755) }

        it 'is a git repository' do
          cmd = command("git -C #{repo_path} rev-parse")
          expect(cmd.exit_status).to be_zero
        end

        it 'has the correct origin' do
          cmd = command("git -C #{repo_path} remote get-url origin")
          expect(cmd.exit_status).to be_zero
          expect(cmd.stdout.rstrip).to eq(repo_url)
        end

        it 'is on the correct branch' do
          cmd = command("git -C #{repo_path} rev-parse --abbrev-ref HEAD")
          expect(cmd.exit_status).to be_zero
          expect(cmd.stdout.rstrip).to eq('stable')
        end
      end
    end

    context command('/usr/local/src/arcanist/bin/arc version') do
      its(:exit_status) { is_expected.to be_zero }
    end

    context command('/usr/local/src/libphutil/src/parser/xhpast/bin/xhpast --version') do
      its(:exit_status) { is_expected.to be_zero }
    end

    context command('/usr/local/src/phabricator/bin/config list') do
      its(:exit_status) { is_expected.to be_zero }
    end
  end
end
