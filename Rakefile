require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.send('disable_class_inherits_from_params_class')
PuppetLint.configuration.send('disable_80chars')

task :default => [:lint]
