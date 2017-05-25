require_relative '../spec_helper_acceptance'
require 'sshkey'

RSpec.describe 'phabricator::almanac' do
  key = SSHKey.generate

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

    class { 'phabricator::almanac':
      device      => 'test',
      private_key => '#{key.private_key}',
    }
  EOS

  # TODO: We can't properly test this class at the moment because there is no
  # way to create an Almanac device through the CLI or API. See
  # https://secure.phabricator.com/T12414.

  it 'applies with no errors' do
    apply_manifest(pp, catch_failures: false)
  end

  context file('/usr/local/src/phabricator/conf/keys/device.key') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by('phd') }
    it { is_expected.to be_grouped_into('root') }
    it { is_expected.to be_mode(400) }

    its(:content) { is_expected.to eq(key.private_key) }
  end
end
