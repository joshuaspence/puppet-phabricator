source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper', :require => false
  gem 'puppet-blacksmith', :require => false
  gem 'puppet-lint', :require => false
  gem 'rake', :require => false
  gem 'rspec-puppet', :require => false
  gem 'rspec-system-puppet', :require => false
  gem 'rspec-system-serverspec', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
