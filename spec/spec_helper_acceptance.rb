require 'beaker-rspec/spec_helper'

require 'beaker/puppet_install_helper'
run_puppet_install_helper

require 'beaker/module_install_helper'
install_module
install_module_dependencies
install_module_from_forge('puppetlabs-mysql', '~> 3')

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
    default[:default_apply_opts][:order] = ENV['ORDERING'] if ENV['ORDERING']
  end
end
