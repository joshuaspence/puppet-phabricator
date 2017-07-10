require_relative '../spec_helper'

RSpec.describe 'phabricator', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      context 'phabricator::config' do
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
          is_expected.to contain_user('diffusion')
            .with_ensure('present')
            .with_comment('Phabricator VCS')
            .with_gid('phabricator')
            .with_home('/var/repo')
            .with_managehome(false)
            .with_shell('/bin/sh')
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
          is_expected.to contain_file('/var/repo')
            .with_ensure('directory')
            .with_owner('phd')
            .with_group('phabricator')
            .with_mode('0750')
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
          let(:params) do
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
          let(:params) do
            {
              storage_upgrade: false,
            }
          end

          it { is_expected.not_to contain_exec('bin/storage upgrade') }
        end

        context 'when $storage_upgrade is enabled' do
          let(:params) do
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

        context 'when $manage_diffusion is true' do
          let(:params) do
            {
              manage_diffusion: true,
            }
          end

          it do
            is_expected.to contain_sudo__conf('diffusion:phd')
              .with_ensure('present')
              .with_content(
                format(
                  '%s ALL=(%s) SETENV: NOPASSWD: %s',
                  'diffusion',
                  'phd:phabricator',
                  [
                    '/usr/bin/git-receive-pack',
                    '/usr/bin/git-upload-pack',
                    '/usr/bin/ssh',
                  ].join(', '),
                ),
              )
          end

          it do
            is_expected.to contain_sudo__conf('www-data:phd')
              .with_ensure('present')
              .with_content(
                format(
                  '%s ALL=(%s) SETENV: NOPASSWD: %s',
                  'www-data',
                  'phd:phabricator',
                  [
                    '/usr/bin/ssh',
                    '/usr/lib/git-core/git-http-backend',
                  ].join(', '),
                ),
              )
          end

          it do
            is_expected.to contain_ssh__server__config__setting('diffusion')
              .with_key('Match User diffusion')
              .with_value([
                '',
                'AuthorizedKeysCommand /usr/local/src/phabricator/bin/ssh-auth',
                'AuthorizedKeysCommandUser diffusion',
              ].join("\n  "))
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
                'diffusion.ssh-user' => 'diffusion',
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
                'diffusion.ssh-user' => 'diffusion',
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

      context 'phabricator::install' do
        it { is_expected.to contain_class('git') }
        it { is_expected.to contain_class('php') }
        it { is_expected.to contain_php__extension('apcu').with_package_prefix('php-') }
        it { is_expected.to contain_php__extension('curl') }
        it { is_expected.to contain_php__extension('gd') }
        it { is_expected.to contain_php__extension('mbstring') }
        it { is_expected.to contain_php__extension('mysql').with_so_name('mysqli') }

        %w[arcanist libphutil phabricator].each do |repo|
          it do
            is_expected.to contain_vcsrepo(repo).only_with(
              ensure: 'latest',
              provider: 'git',
              path: "/usr/local/src/#{repo}",
              source: "https://github.com/phacility/#{repo}.git",
              revision: 'stable',
            )
          end
        end

        it do
          is_expected.to contain_exec('build_xhpast.php')
            .with_command('/usr/local/src/libphutil/scripts/build_xhpast.php')
            .with_refreshonly(true)
            .that_requires('Class[php::cli]')
            .that_requires('Package[g++]')
            .that_requires('Package[make]')
            .that_subscribes_to('Vcsrepo[libphutil]')
        end

        context 'when $install_dir is specified' do
          let(:install_dir) { '/opt' }
          let(:params) do
            {
              install_dir: install_dir,
            }
          end

          %w[arcanist libphutil phabricator].each do |repo|
            it { is_expected.to contain_vcsrepo(repo).with_path("#{install_dir}/#{repo}") }
          end

          it do
            is_expected.to contain_exec('build_xhpast.php')
              .with_command("#{install_dir}/libphutil/scripts/build_xhpast.php")
          end
        end

        context 'when $arcanist_revision is specified' do
          let(:params) do
            {
              arcanist_revision: revision,
            }
          end
          let(:revision) { 'master' }

          it { is_expected.to contain_vcsrepo('arcanist').with_revision(revision) }
        end

        context 'when $libphutil_revision is specified' do
          let(:params) do
            {
              libphutil_revision: revision,
            }
          end
          let(:revision) { 'master' }

          it { is_expected.to contain_vcsrepo('libphutil').with_revision(revision) }
        end

        context 'when $phabricator_revision is specified' do
          let(:params) do
            {
              phabricator_revision: revision,
            }
          end
          let(:revision) { 'master' }

          it { is_expected.to contain_vcsrepo('phabricator').with_revision(revision) }
        end
      end
    end
  end
end
