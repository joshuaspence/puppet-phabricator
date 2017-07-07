require_relative '../spec_helper'

RSpec.describe 'phabricator::config', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      include_context :module_precondition

      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_group('phabricator')
          .with_ensure('present')
          .with_system(true)
      end

      it do
        is_expected.to contain_user('phd')
          .with_ensure('present')
          .with_comment('Phabricator Daemons')
          .with_gid('phabricator')
          .with_home('/run/phabricator')
          .with_managehome(false)
          .with_shell('/usr/sbin/nologin')
          .with_system(true)
      end

      it do
        is_expected.to contain_file('/var/log/phabricator')
          .with_ensure('directory')
          .with_owner('root')
          .with_group('phabricator')
          .with_mode('0775')
      end

      it do
        is_expected.to contain_file('/run/phabricator')
          .with_ensure('directory')
          .with_owner('root')
          .with_group('phabricator')
          .with_mode('0775')
      end

      it do
        is_expected.to contain_file('phabricator/conf/local.json')
          .with_ensure('file')
          .with_path('/usr/local/src/phabricator/conf/local/local.json')
          .with_owner('root')
          .with_group('phabricator')
          .with_mode('0640')
          .that_requires('Vcsrepo[phabricator]')
      end

      context 'when $install_dir is specified' do
        let(:install_dir) { '/opt' }
        let(:module_params) do
          {
            install_dir: install_dir,
          }
        end

        it do
          is_expected.to contain_file('phabricator/conf/local.json')
            .with_path("#{install_dir}/phabricator/conf/local/local.json")
        end
      end

      context 'when $storage_upgrade is disabled' do
        let(:module_params) do
          {
            storage_upgrade: false,
          }
        end

        it { is_expected.not_to contain_exec('bin/storage upgrade') }
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
          is_expected.to contain_exec('bin/storage upgrade')
            .with_command([
              '/usr/local/src/phabricator/bin/storage',
              'upgrade',
              '--force',
              "--user=#{username}",
              "--password=#{password}",
            ].join(' '))
            .with_refreshonly(true)
            .with_timeout(0)
            .that_requires('Class[php::cli]')
            .that_requires('File[phabricator/conf/local.json]')
            .that_requires('Php::Extension[mysql]')
            .that_requires('Vcsrepo[arcanist]')
            .that_requires('Vcsrepo[libphutil]')
            .that_subscribes_to('Vcsrepo[phabricator]')
        end
      end
    end
  end
end
