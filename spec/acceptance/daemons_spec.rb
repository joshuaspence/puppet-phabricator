require_relative '../spec_helper_acceptance'

RSpec.describe 'phabricator::daemons' do
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
    }

    include phabricator::daemons
  EOS

  # TODO: Move this to a shared example.
  it 'applies with no errors' do
    apply_manifest(pp, catch_failures: true)
  end

  it 'applies a second time without changes' do
    apply_manifest(pp, catch_changes: true)
  end

  context file('/etc/systemd/system/phd.service') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by('root') }
    it { is_expected.to be_grouped_into('root') }
  end

  context service('phd') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  context command('/usr/local/src/phabricator/bin/phd status --local') do
    its(:exit_status) { is_expected.to be_zero }
  end

  context command('/usr/local/src/phabricator/bin/phd log') do
    its(:exit_status) { is_expected.to be_zero }
  end

  context command('logrotate --debug /etc/logrotate.d/phd') do
    its(:exit_status) { is_expected.to be_zero }
  end
end
