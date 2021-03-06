require 'beaker-rspec/spec_helper'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'

RSpec.configure do |config|
  config.default_formatter = :documentation

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended.
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Set default options for `puppet apply`.
  config.before(:suite) do
    default[:default_apply_opts] ||= {}
    default[:default_apply_opts][:strict_variables] = nil
    default[:default_apply_opts][:ordering] = ENV['ORDERING'] if ENV['ORDERING']
  end

  config.before(:suite) do
    # Install Puppet.
    run_puppet_install_helper

    # Install `librarian-puppet`.
    hosts.each do |host|
      install_package(host, 'git')
      install_package(host, 'rubygems')
      on(host, 'gem install --no-document librarian-puppet')
    end

    # Install module and dependencies.
    #
    # NOTE: I am using `librarian-puppet` because it seems to do a better job at
    # finding compatible versions of dependencies than `install_module_dependencies`.
    hosts.each do |host|
      install_module_on(host)
      on(host, "cd #{host['distmoduledir']}/phabricator && librarian-puppet install --verbose --path #{host['distmoduledir']}")
    end
  end

  # Install and configure resources which are required for the acceptance tests.
  config.before(:suite) do
    hosts.each do |host|
      if fact_on(host, 'operatingsystem') == 'Ubuntu'
        # These packages are required by the `apt` module.
        if fact_on(host, 'operatingsystemrelease') < '14.04'
          install_package(host, 'python-software-properties')
        else
          install_package(host, 'software-properties-common')
        end

        install_package(host, 'apt-transport-https')
        install_package(host, 'ca-certificates')
      end

      # Install and configure MySQL.
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

        # These packages are required for serverspec tests.
        ensure_packages(['login', 'net-tools', 'sudo'])
      EOS

      install_module_from_forge_on(host, 'puppetlabs-mysql', '~> 6')
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
  end
end
