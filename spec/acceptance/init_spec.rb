require_relative '../spec_helper_acceptance'

RSpec.describe 'phabricator' do
  pp = <<-EOS
    class { 'mysql::server':
      override_options        => {
        max_allowed_packet => '32M',
        sql_mode           => 'STRICT_ALL_TABLES',
      },
      remove_default_accounts => true,
      restart                 => true,
      root_password           => 'root',
      create_root_user        => true,
    }
  EOS

  # Dependencies may require multiple runs.
  apply_manifest(pp, catch_failures: true)
  apply_manifest(pp, catch_changes: true)

  pp = <<-EOS
    class { 'php':
      ensure       => 'latest',
      manage_repos => false,
      fpm          => false,
      dev          => true,
      composer     => false,
      pear         => true,
      settings     => {},
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
    }

    class { 'phabricator::mail':
      domain => 'example.com',
    }
  EOS

  it 'applies with no errors' do
    apply_manifest(pp, catch_failures: true)
  end

  it 'applies a second time without changes' do
    apply_manifest(pp, catch_changes: true)
  end

  describe 'phabricator::config' do
    context group('phabricator') do
      it { is_expected.to exist }
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

    context file('/usr/local/src/phabricator/conf/local/local.json') do
      it { is_expected.to be_file }
      it { is_expected.to be_owned_by('root') }
      it { is_expected.to be_grouped_into('phabricator') }
      it { is_expected.to be_mode(640) }

      its(:content_as_json) do
        is_expected.to include(
          'diffusion.ssh-user' => 'vcs',
          'log.access.path' => '/var/log/phabricator/access.log',
          'log.ssh.path' => '/var/log/phabricator/ssh.log',
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
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.not_to contain('Not Applied') }
    end
  end

  describe 'phabricator::install' do
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
      its(:exit_status) { is_expected.to eq(0) }
    end

    context command('/usr/local/src/libphutil/src/parser/xhpast/bin/xhpast --version') do
      its(:exit_status) { is_expected.to be_zero }
    end

    context command('/usr/local/src/phabricator/bin/config list') do
      its(:exit_status) { is_expected.to eq(0) }
    end
  end

  describe 'phabricator::mail' do
    context command('php --modules') do
      its(:stdout) { is_expected.to match(/^mailparse$/) }
    end

    context command("echo -e 'Subject: Testing inbound mail\n\nThis is a test' | sendmail phabriator") do
      its(:exit_status) { is_expected.to be_zero }
    end

    context command('/usr/local/src/phabricator list-inbound') do
      its(:exit_status) { is_expected.to be_zero }
      its(:stdout) { is_expected.to contain('Testing inbound mail') }
    end
  end
end
