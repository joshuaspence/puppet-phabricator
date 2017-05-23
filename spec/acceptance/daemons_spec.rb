require_relative '../spec_helper_acceptance'

RSpec.describe 'phabricator::daemons' do
  # TODO: This is mostly copied from `spec/acceptance/init_spec.rb` and should
  # be consolidated.
  pp = <<-EOS
    include apt

    Apt::Ppa {
      package_manage => true,
    }

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

  it 'applies with no errors' do
    apply_manifest(pp, catch_failures: true)
  end

  it 'applies a second time without changes' do
    apply_manifest(pp, catch_changes: true)
  end

  context file('/var/repo') do
    it { is_expected.to be_directory }
    it { is_expected.to be_owned_by('phd') }
    it { is_expected.to be_grouped_into('phabricator') }
    it { is_expected.to be_mode(755) }
  end

  context user('phd') do
    it { is_expected.to exist }
    it { is_expected.to belong_to_primary_group('phabricator') }
    it { is_expected.to have_home_directory('/run/phabricator') }
    it { is_expected.to have_login_shell('/usr/sbin/nologin') }
  end

  context command('sudo --login --user=phd') do
    its(:exit_status) { is_expected.not_to be_zero }
    its(:stdout) { is_expected.to contain('This account is currently not available.') }
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

  context process('php ./phd-daemon') do
    it { is_expected.to be_running }

    its(:count) { is_expected.to eq(1) }
    its(:group) { is_expected.to eq('phabricator') }
    its(:user) { is_expected.to eq('phd') }
  end
end
