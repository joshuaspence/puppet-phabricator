require_relative '../spec_helper'

RSpec.describe 'phabricator::daemons', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      include_context :module_precondition

      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_file('/var/repo')
          .with_ensure('directory')
          .with_owner('phd')
          .with_group('phabricator')
          .with_mode('0755')
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
        is_expected.to contain_systemd__unit_file('phd.service')
          .with_ensure('file')
          .with_content(/^Requires=network\.target$/)
          .with_content(/^After=network\.target$/)
          .with_content(/^Type=forking$/)
          .with_content(%r{^ExecStart=/usr/local/src/phabricator/bin/phd start$})
          .with_content(%r{^ExecReload=/usr/local/src/phabricator/bin/phd restart$})
          .with_content(%r{^ExecStop=/usr/local/src/phabricator/bin/phd stop$})
          .with_content(/^User=phd$/)
          .with_content(/^Group=phabricator$/)
          .with_content(/^WantedBy=multi-user\.target$/)
          .that_notifies('Service[phd]')
      end

      it do
        is_expected.to contain_service('phd')
          .with_ensure('running')
          .with_enable(true)
          .that_requires('Exec[systemctl-daemon-reload]')
          .that_requires('File[/var/log/phabricator]')
          .that_requires('File[/run/phabricator]')
          .that_requires('File[/var/repo]')
          .that_requires('Group[phabricator]')
          .that_requires('User[phd]')
          .that_subscribes_to('Class[php::cli]')
          .that_subscribes_to('File[phabricator/conf/local.json]')
          .that_subscribes_to('Vcsrepo[libphutil]')
          .that_subscribes_to('Vcsrepo[phabricator]')
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
          is_expected.to contain_service('phd')
            .that_requires('Exec[bin/storage upgrade]')
        end
      end

      context 'when $run_daemon is set' do
        let(:params) do
          {
            daemon: 'repo',
          }
        end

        it do
          is_expected.to contain_systemd__unit_file('phd.service')
            .with_content(
              %r{^ExecStart=/usr/local/src/phabricator/bin/phd launch repo$},
            )
        end
      end
    end
  end
end
