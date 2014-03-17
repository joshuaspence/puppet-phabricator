require 'spec_helper_system'

describe 'phabricator class:' do
  context 'should run successfully' do
    it 'should run successfully' do
      pp = "class { 'phabricator': }"

      puppet_apply(pp) do |r|
        #r.stderr.should be_empty
        [0,2].should include r.exit_code
        r.refresh
        #r.stderr.should be_empty
        r.exit_code.should be_zero
      end
    end
  end

  #describe package(package_name) do
  #  it { should be_installed }
  #end

  #describe service('nginx') do
  #  it { should be_running }
  #end
end
