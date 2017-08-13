require_relative '../spec_helper'

RSpec.describe 'phabricator::aphlict', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      include_context :module_precondition

      let(:facts) do
        facts
      end

      let(:default_config) do
        {
          servers: [
            {
              listen: '0.0.0.0',
              port: 22280,
              type: 'client',
            },
            {
              listen: '127.0.0.1',
              port: 22281,
              type: 'admin',
            },
          ],
          logs: [
            {
              path: '/var/log/phabricator/aphlict.log',
            },
          ],
          cluster: [],
          pidfile: '/run/phabricator/aphlict.pid',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_file('phabricator/conf/aphlict.json')
          .with_ensure('file')
          .with_path('/usr/local/src/phabricator/conf/aphlict/aphlict.custom.json')
          .with_content(default_config.to_json)
          .with_owner('root')
          .with_group('root')
          .with_mode('0644')
          .that_notifies('Service[aphlict]')
          .that_requires('Vcsrepo[phabricator]')
      end

      it do
        is_expected.to contain_user('aphlict')
          .with_ensure('present')
          .with_comment('Phabricator Aphlict')
          .with_gid('phabricator')
          .with_home('/run/phabricator')
          .with_managehome(false)
          .with_shell('/usr/sbin/nologin')
          .with_system(true)
      end

      it { is_expected.to contain_class('nodejs') }

      it do
        is_expected.to contain_nodejs__npm('ws')
          .with_ensure('present')
          .with_target('/usr/local/src/phabricator/support/aphlict/server')
          .that_notifies('Service[aphlict]')
          .that_requires('Vcsrepo[phabricator]')
      end

      it do
        is_expected.to contain_systemd__unit_file('aphlict.service')
          .with_ensure('file')
          .with_content(/^Requires=network\.target$/)
          .with_content(/^After=network\.target$/)
          .with_content(/^Type=forking$/)
          .with_content(%r{^ExecStart=/usr/local/src/phabricator/bin/aphlict start$})
          .with_content(%r{^ExecReload=/usr/local/src/phabricator/bin/aphlict restart$})
          .with_content(%r{^ExecStop=/usr/local/src/phabricator/bin/aphlict stop$})
          .with_content(/^User=aphlict$/)
          .with_content(/^Group=phabricator$/)
          .with_content(/^WantedBy=multi-user\.target$/)
          .that_notifies('Service[aphlict]')
      end

      it do
        is_expected.to contain_service('aphlict')
          .with_ensure('running')
          .with_enable(true)
          .that_requires('Exec[systemctl-daemon-reload]')
          .that_requires('File[/var/log/phabricator]')
          .that_requires('File[/run/phabricator]')
          .that_requires('Group[phabricator]')
          .that_requires('User[aphlict]')
          .that_subscribes_to('Class[nodejs::install]')
          .that_subscribes_to('Vcsrepo[phabricator]')
      end

      it do
        is_expected.to contain_logrotate__rule('aphlict')
          .with_ensure('present')
          .with_path('/var/log/phabricator/aphlict.log')
          .with_compress(true)
          .with_copytruncate(true)
          .with_delaycompress(true)
          .with_ifempty(false)
          .with_missingok(true)
          .with_rotate(7)
          .with_rotate_every('day')
          .with_su(true)
          .with_su_owner('root')
          .with_su_group('phabricator')
      end
    end
  end
end
