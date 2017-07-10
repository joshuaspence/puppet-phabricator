# Class for installing Phabricator Daemons.
#
# @summary This class manages Phabricator Daemons. See
# {https://secure.phabricator.com/book/phabricator/article/managing_daemons/
# Managing Daemons with phd}.
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
#   include phabricator::daemons
#
# @param daemon Launch the specified daemon using `./bin/phd launch` instead of
#   starting all of the daemon daemons.
#
class phabricator::daemons(
  Optional[String] $daemon,
) {
  # TODO: The `strict_indent` check doesn't seem to work properly here. See
  # https://github.com/relud/puppet-lint-strict_indent-check/issues/11.
  #
  # lint:ignore:strict_indent
  systemd::unit_file { 'phd.service':
    ensure  => 'file',
    content => epp('phabricator/daemons.systemd.epp', {
      command => "${phabricator::install_dir}/phabricator/bin/phd",
      daemon  => $daemon,
      user    => $phabricator::daemon_user,
      group   => $phabricator::group,
    }),
    notify  => Service['phd'],
  }
  # lint:endignore

  # TODO: Should we also specify `hasrestart => true`? According to the
  # documentation the default value is `false`, although I am somewhat
  # surprised by this.
  service { 'phd':
    ensure    => 'running',
    enable    => true,
    require   => [
      Exec['systemctl-daemon-reload'],
      File[$phabricator::logs_dir],
      File[$phabricator::pid_dir],
      File[$phabricator::repo_dir],
      Group[$phabricator::group],
      User[$phabricator::daemon_user],
    ],
    subscribe => [
      Class['php::cli'],
      File['phabricator/conf/local.json'],
      Vcsrepo['libphutil'],
      Vcsrepo['phabricator'],
    ],
  }

  # Restart the daemons if any PHP extensions are updated.
  Php::Extension <| |> ~> Service['phd']

  if $phabricator::storage_upgrade {
    Exec['bin/storage upgrade'] -> Service['phd']
  }
}
