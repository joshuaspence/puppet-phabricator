require 'rspec-system/spec_helper'
require 'rspec-system-puppet/helpers'
require 'rspec-system-serverspec/helpers'
include RSpecSystemPuppet::Helpers

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Enable colour
  c.tty = true

  # This is where we 'setup' the nodes before running our tests
  c.before :suite do
    # Install puppet
    puppet_install

    # Install modules and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'phabricator')
    shell('puppet module install jfryman-nginx')
    shell('puppet module install puppetlabs-mysql')
    shell('puppet module install puppetlabs-nodejs')
    shell('puppet module install puppetlabs-stdlib')
    shell('puppet module install puppetlabs-vcsrepo')
    shell('puppet module install thias-php')
  end
end
