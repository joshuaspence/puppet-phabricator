require 'fuubar'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

# rubocop:disable Style/MixinUsage
include RspecPuppetFacts
# rubocop:enable Style/MixinUsage

# Require all support files.
Dir['./spec/support/**/*.rb'].each { |file| require file }

RSpec.configure do |config|
  # http://betterspecs.org/#formatter
  config.default_formatter = Fuubar

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended.
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on a
    # real object. This is generally recommended, and will default to `true` in
    # RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # rspec-puppet
  config.strict_variables = true
end
