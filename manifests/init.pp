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
# @param vcs_user
#
class phabricator(
  Phabricator::Revision $arcanist_revision,
  Phabricator::Revision $libphutil_revision,
  Phabricator::Revision $phabricator_revision,
  Hash[String, Data] $config_hash,
  Boolean $storage_upgrade,
  Optional[String] $storage_upgrade_user,
  Optional[String] $storage_upgrade_password,

  String $daemon_user,
  String $group,
  Stdlib::Unixpath $install_dir,
  Stdlib::Unixpath $logs_dir,
  Stdlib::Unixpath $pid_dir,
  String $vcs_user,
) {
  if $storage_upgrade {
    assert_type(String, $storage_upgrade_user)
    assert_type(String, $storage_upgrade_password)
  }

  $config = merge(
    $config_hash,
    {
      'diffusion.ssh-user' => $vcs_user,
      'log.access.path' => "${logs_dir}/access.log",
      'log.ssh.path' => "${logs_dir}/ssh.log",
      'phd.log-directory' => $logs_dir,
      'phd.pid-directory' => $pid_dir,
      'phd.user' => $daemon_user,
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
