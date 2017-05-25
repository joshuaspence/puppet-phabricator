require_relative '../spec_helper'

RSpec.describe 'phabricator::almanac', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      include_context :module_precondition

      let(:facts) do
        facts
      end

      let(:params) do
        {
          device: 'test',
          private_key: 'test',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_file('phabricator/conf/device.key')
          .with_ensure('file')
          .with_path('/usr/local/src/phabricator/conf/keys/device.key')
          .with_content(params[:private_key])
          .with_owner('phd')
          .with_group('root')
          .with_mode('0400')
          .that_notifies('Exec[almanac register]')
          .that_requires('Vcsrepo[phabricator]')
      end

      it do
        is_expected.to contain_exec('almanac register')
          .with_command([
            '/usr/local/src/phabricator/bin/almanac register',
            "--device #{params[:device]}",
            '--force',
            '--private-key /usr/local/src/phabricator/conf/keys/device.key',
          ].join(' '))
          .with_refreshonly(true)
          .that_requires('Class[php::cli]')
          .that_requires('File[phabricator/conf/local.json]')
          .that_requires('Php::Extension[mysql]')
          .that_requires('Vcsrepo[libphutil]')
          .that_requires('Vcsrepo[phabricator]')
      end

      context 'when $storage_upgrade is enabled' do
        let(:module_params) do
          {
            storage_upgrade: true,
            storage_upgrade_user: username,
            storage_upgrade_password: password,
          }
        end
        let(:password) { 'password' }
        let(:username) { 'root' }

        it do
          is_expected.to contain_exec('almanac register')
            .that_requires('Exec[bin/storage upgrade]')
        end
      end
    end
  end
end
