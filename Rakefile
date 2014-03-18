require 'bundler'
Bundler.require(:default, :test)

require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet_blacksmith/rake_tasks'

PuppetLint.configuration.send('disable_class_inherits_from_params_class')
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = ['pkg/**/*.pp']

desc 'Validate manifests, templates, and ruby files in lib.'
task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['lib/**/*.rb'].each do |lib_file|
    sh "ruby -c #{lib_file}"
  end
  Dir['templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end

task :default => [:lint, :validate]
