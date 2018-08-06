require_relative '../spec_helper_acceptance'

RSpec.describe 'phabricator::aphlict' do
  # TODO: This is mostly copied from `spec/acceptance/init_spec.rb` and should
  # be consolidated.
  pp = <<-EOS
    include apt

    Apt::Ppa {
      package_manage => true,
    }

    # Ensure that `apt-get update` is executed before any packages are
    # installed. See https://github.com/puppetlabs/puppetlabs-apt/#adding-new-sources-or-ppas.
    Class['apt::update'] -> Package <| title != 'apt-transport-https' and title != 'ca-certificates' and title != 'software-properties-common' |>

    # Ensure that NodeJS and NPM are installed before attempting to install
    # any NPM packages.
    Class['nodejs::install'] -> Package <| provider == 'npm' |>

    class { 'php::globals':
      php_version => '7.2',
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
    }

    class { 'nodejs':
      repo_url_suffix => '8.x',
    }

    include phabricator::aphlict

    package { 'wscat2':
      ensure   => 'installed',
      provider => 'npm',
    }
  EOS

  # TODO: Move this to a shared example.
  it 'applies with no errors' do
    apply_manifest(pp, catch_failures: true)
  end

  it 'applies a second time without changes' do
    apply_manifest(pp, catch_changes: true)
  end

  context file('/usr/local/src/phabricator/conf/aphlict/aphlict.custom.json') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by('root') }
    it { is_expected.to be_grouped_into('root') }
    it { is_expected.to be_mode(644) }

    its(:content_as_json) do
      is_expected.to eq(
        'servers' => [
          {
            'listen' => '0.0.0.0',
            'port' => 22280,
            'type' => 'client',
          },
          {
            'listen' => '127.0.0.1',
            'port' => 22281,
            'type' => 'admin',
          },
        ],
        'logs' => [
          {
            'path' => '/var/log/phabricator/aphlict.log',
          },
        ],
        'cluster' => [],
        'pidfile' => '/run/phabricator/aphlict.pid',
      )
    end
  end

  context user('aphlict') do
    it { is_expected.to exist }
    it { is_expected.to belong_to_primary_group('phabricator') }
    it { is_expected.to have_home_directory('/run/phabricator') }
    it { is_expected.to have_login_shell('/usr/sbin/nologin') }
  end

  context command('sudo --login --user=aphlict') do
    its(:exit_status) { is_expected.not_to be_zero }
    its(:stdout) { is_expected.to contain('This account is currently not available.') }
  end

  context file('/etc/systemd/system/aphlict.service') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by('root') }
    it { is_expected.to be_grouped_into('root') }
  end

  context service('aphlict') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  context port(22280) do
    it { is_expected.to be_listening.on('0.0.0.0').with('tcp') }
  end

  context port(22281) do
    it { is_expected.to be_listening.on('127.0.0.1').with('tcp') }
  end

  context command('/usr/local/src/phabricator/bin/aphlict status') do
    its(:exit_status) { is_expected.to be_zero }
  end

  context command('curl --fail http://127.0.0.1:22281/status/') do
    its(:exit_status) { is_expected.to be_zero }
  end

  context command('echo | wscat ws://127.0.0.1:22280') do
    its(:exit_status) { is_expected.to be_zero }
  end

  context command('logrotate --debug /etc/logrotate.d/aphlict') do
    its(:exit_status) { is_expected.to be_zero }
  end
end
