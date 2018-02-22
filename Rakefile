require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet_blacksmith/rake_tasks'
require 'puppet-strings/tasks'
require 'rubocop/rake_task'

task :markdown_lint do
  # `markdownlint` doesn't currently provide an API that can be used to
  # properly construct a Rake task. See https://github.com/mivok/markdownlint/issues/131.
  sh 'mdl --git-recurse --rules ~MD024 .'
end

require 'metadata-json-lint/rake_task'
MetadataJsonLint.options[:strict_dependencies] = true

require 'puppet-lint/tasks/puppet-lint'
PuppetLint::RakeTask.new do |config|
  config.fail_on_warnings = true
  config.ignore_paths = ['pkg/**/*', 'spec/fixtures/**/*', 'vendor/**/*']
  config.relative = true
end

require 'puppet-syntax/tasks/puppet-syntax'
PuppetSyntax.exclude_paths = ['pkg/**/*', 'spec/fixtures/**/*', 'vendor/**/*']
PuppetSyntax.check_hiera_keys = true

task :travis_lint do
  require 'travis'

  # TODO: Ideally `exit_code` would be set to `true`, but `travis lint`
  # currently generates bogus warnings for valid `matrix.include` keys.
  # See https://github.com/travis-ci/travis.rb/issues/376.
  lint = Travis::CLI::Lint.new(exit_code: false)
  lint.run
end

Rake::Task[:default].clear
task default: [
  :syntax,
  :lint,
  :rubocop,
  :metadata_lint,
  :markdown_lint,
  :travis_lint,
]
