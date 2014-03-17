require 'spec_helper'

describe 'phabricator::config' do
  describe 'with defaults' do
    it { should contain_class('phabricator::params') }
    it { should contain_file('/usr/src').only_with(
      :path => '/usr/src',
      :ensure => 'directory',
      #:owner => 'root',
      #:group => 'root',
      #:mode => '0644',
    )}
  end
end
