require_relative '../spec_helper'

RSpec.describe 'phabricator', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('phabricator::config') }
      it { is_expected.to contain_class('phabricator::install') }

      context 'when $storage_upgrade is enabled' do
        let(:params) do
          {
            storage_upgrade: true,
            storage_upgrade_user: 'root',
            storage_upgrade_password: 'password',
          }
        end

        %i[storage_upgrade_user storage_upgrade_password].each do |param|
          context "when $#{param} is not defined" do
            let(:params) do
              super().tap do |params|
                params.delete(param)
              end
            end

            it do
              is_expected.to compile
                .and_raise_error(/assert_type\(\): expects a String value, got Undef/)
            end
          end
        end
      end

      describe 'File[phabricator/conf/local.json]' do
        subject do
          resource = catalogue.resource('file', 'phabricator/conf/local.json')
          config = resource.send(:parameters)[:content]
          JSON.parse(config)
        end

        context 'with defaults' do
          it do
            is_expected.to eq(
              'log.access.path' => '/var/log/phabricator/access.log',
              'log.ssh.path' => '/var/log/phabricator/ssh.log',
              'phd.log-directory' => '/var/log/phabricator',
              'phd.pid-directory' => '/run/phabricator',
              'phd.user' => 'phd',
              'repository.default-local-path' => '/var/repo',
            )
          end
        end

        context 'with $config_hash' do
          let(:config_hash) do
            {
              'mysql.host' => 'localhost',
              'mysql.user' => 'user',
              'mysql.pass' => 'password',
            }
          end
          let(:params) do
            {
              config_hash: config_hash,
            }
          end

          it do
            is_expected.to eq(
              'log.access.path' => '/var/log/phabricator/access.log',
              'log.ssh.path' => '/var/log/phabricator/ssh.log',
              'mysql.host' => config_hash['mysql.host'],
              'mysql.user' => config_hash['mysql.user'],
              'mysql.pass' => config_hash['mysql.pass'],
              'phd.log-directory' => '/var/log/phabricator',
              'phd.pid-directory' => '/run/phabricator',
              'phd.user' => 'phd',
              'repository.default-local-path' => '/var/repo',
            )
          end
        end
      end
    end
  end
end
