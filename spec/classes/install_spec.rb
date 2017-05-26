require_relative '../spec_helper'

RSpec.describe 'phabricator::install', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      include_context :module_precondition

      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

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
        let(:module_params) do
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
        let(:module_params) do
          {
            arcanist_revision: revision,
          }
        end
        let(:revision) { 'master' }

        it { is_expected.to contain_vcsrepo('arcanist').with_revision(revision) }
      end

      context 'when $libphutil_revision is specified' do
        let(:module_params) do
          {
            libphutil_revision: revision,
          }
        end
        let(:revision) { 'master' }

        it { is_expected.to contain_vcsrepo('libphutil').with_revision(revision) }
      end

      context 'when $phabricator_revision is specified' do
        let(:module_params) do
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
