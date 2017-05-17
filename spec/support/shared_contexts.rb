# A shared context to `include` the module under test.
#
# This is useful for testing Puppet classes which have a dependency on their
# parent class. For example, in order to test the `phabricator::config` class
# using `rspec-puppet`, we must first include the parent (`phabricator`) class
# in order to define the necessary `$phabricator::*` variables.
#
# This code is based on `RSpec::Puppet#test_manifest`.
RSpec.shared_context(:module_precondition) do
  let(:pre_condition) do
    params = module_params if respond_to?(:module_params)
    test_module = class_name.split('::').first

    if params.nil? || params.empty?
      "include #{test_module}"
    else
      "class { '#{test_module}': #{param_str_from_hash(module_params)} }"
    end
  end
end
