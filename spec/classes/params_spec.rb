require 'spec_helper'

describe 'phabricator::params' do
  # Only phabricator::params itself
  it { should have_class_count(1) }

  # params class should never declare resources
  it { should have_resource_count(0) }
end
