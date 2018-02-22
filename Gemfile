source 'https://rubygems.org'

gem 'puppet', ENV['PUPPET_GEM_VERSION'], require: false

group :development do
  gem 'fuubar', require: false
  gem 'mdl', require: false
  gem 'metadata-json-lint', require: false
  gem 'puppet-blacksmith', require: false
  gem 'puppet-strings', require: false
  gem 'puppet-syntax', require: false
  gem 'puppetlabs_spec_helper', require: false
  gem 'rspec-puppet', require: false
  gem 'rspec-puppet-facts', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'travis', require: false

  gem 'puppet-lint', require: false
  gem 'puppet-lint-absolute_template_path', require: false
  gem 'puppet-lint-alias-check', require: false
  gem 'puppet-lint-classes_and_types_beginning_with_digits-check', require: false
  gem 'puppet-lint-duplicate_class_parameters-check', require: false
  gem 'puppet-lint-empty_string-check', require: false
  gem 'puppet-lint-file_ensure-check', require: false
  gem 'puppet-lint-file_source_rights-check', require: false
  gem 'puppet-lint-leading_zero-check', require: false
  gem 'puppet-lint-legacy_facts-check', require: false
  gem 'puppet-lint-no_erb_template-check', require: false
  gem 'puppet-lint-no_symbolic_file_modes-check', require: false
  gem 'puppet-lint-param-docs', require: false
  gem 'puppet-lint-resource_reference_syntax', require: false
  gem 'puppet-lint-strict_indent-check', require: false
  gem 'puppet-lint-top_scope_facts-check', require: false
  gem 'puppet-lint-trailing_comma-check', require: false
  gem 'puppet-lint-trailing_newline-check', require: false
  gem 'puppet-lint-undef_in_function-check', require: false
  gem 'puppet-lint-unquoted_string-check', require: false
  gem 'puppet-lint-version_comparison-check', require: false
  gem 'puppet-lint-world_writable_files-check', require: false

  # `mixlib-config` is a dependency of `mdl`.
  gem 'mixlib-config', '< 2.2.5', require: false if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.2')
end

group :system_tests do
  gem 'beaker', require: false
  gem 'beaker-module_install_helper', require: false
  gem 'beaker-puppet_install_helper', require: false
  gem 'beaker-rspec', require: false
  gem 'serverspec', require: false
  gem 'sshkey', require: false
end
