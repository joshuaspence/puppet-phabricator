# Class for installing Phabricator.
#
# @summary This class configures and installs Phabricator.
#
# @example
#   class { 'phabricator':
#     config_hash => {
#       'mysql.host' => 'localhost',
#       'mysql.user' => 'user',
#       'mysql.pass' => 'password',
#     },
#
#     storage_upgrade          => true,
#     storage_upgrade_user     => 'root',
#     storage_upgrade_password => 'password',
#   }
#
# @param arcanist_revision The commit hash or branch for Arcanist.
# @param libphutil_revision The commit hash or branch for libphutil.
# @param phabricator_revision The commit hash or branch for Phabricator.
# @param config_hash Phabricator configuration. See
#   {https://secure.phabricator.com/book/phabricator/article/advanced_configuration/
#   Configuration User Guide: Advanced Configuration}.
# @param install_fonts Whether to install additional fonts.
# @param manage_diffusion Whether to configure the host in order to be able to
#   serve (either directly or by proxying to another host in the cluster). See
#   {https://secure.phabricator.com/book/phabricator/article/diffusion_hosting/
#   Diffusion User Guide: Repository Hosting}.
# @param storage_upgrade A flag to enable storage upgrades. See
#   {https://secure.phabricator.com/book/phabricator/article/configuration_guide/#storage-configuring-mysql
#   Storage: Configuring MySQL}.
# @param storage_upgrade_user The MySQL user with which to execute
#   `bin/storage upgrade`.
# @param storage_upgrade_password The MySQL password for the storage upgrade
#   user.
#
# @param daemon_user
# @param group
# @param install_dir
# @param logs_dir
# @param pid_dir
# @param repo_dir
# @param vcs_user
#
# TODO: Remove the default values after we drop support for Puppet 4.7.
#
class phabricator(
  Phabricator::Revision $arcanist_revision = 'stable',
  Phabricator::Revision $libphutil_revision = 'stable',
  Phabricator::Revision $phabricator_revision = 'stable',
  Hash[String, Data] $config_hash = {},
  Boolean $install_fonts = false,
  Boolean $manage_diffusion = false,
  Boolean $storage_upgrade = false,
  Optional[String] $storage_upgrade_user = undef,
  Optional[String] $storage_upgrade_password = undef,

  String $daemon_user = 'phd',
  String $group = 'phabricator',
  Stdlib::Unixpath $install_dir = '/usr/local/src',
  Stdlib::Unixpath $logs_dir = '/var/log/phabricator',
  Stdlib::Unixpath $pid_dir = '/run/phabricator',
  Stdlib::Unixpath $repo_dir = '/var/repo',
  String $vcs_user = 'diffusion',
) {
  if $storage_upgrade {
    assert_type(String, $storage_upgrade_user)
    assert_type(String, $storage_upgrade_password)
  }

  $config = merge(
    $config_hash,
    {
      'diffusion.ssh-user' => $vcs_user,
      'environment.append-paths' => ['/usr/lib/git-core'],
      'log.access.path' => "${logs_dir}/access.log",
      'log.ssh.path' => "${logs_dir}/ssh.log",
      'phd.log-directory' => $logs_dir,
      'phd.pid-directory' => $pid_dir,
      'phd.user' => $daemon_user,
      'repository.default-local-path' => $repo_dir,
    }
  )

  # TODO: It's not currently possible to test for warnings with `rspec-puppet`.
  # See https://github.com/rodjek/rspec-puppet/issues/108.
  if $facts['phpversion'] != undef and versioncmp($facts['phpversion'], '7.0.0') >= 0 and versioncmp($facts['phpversion'], '7.1.0') < 0 {
    warning('Phabricator does not support PHP 7.1. See https://secure.phabricator.com/T12101.')
  }

  include phabricator::config
  include phabricator::install
}
