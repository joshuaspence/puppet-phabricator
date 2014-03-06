# == Class: phabricator::db
#
# This module manages the Phabricator Database.
#
# === Parameters
#
# === Variables
#
# === Examples
#
class phabricator::db {
  include '::phabricator::install'

  class { 'mysql::server':
    override_options        => {
      'mysqld' => {
        'bind-address' => $::ipaddress_eth1,
        'sql-mode'     => 'STRICT_ALL_TABLES',
      },
    },
    restart                 => true,
    remove_default_accounts => true,
  }

  mysql_user { "${phabricator::config::user}@phabricator.${::domain}":
    ensure  => present,
    require => Class['mysql::server'],
  }
  mysql_grant { "${phabricator::config::user}@phabricator.${::domain}/`phabricator_%`.*":
    ensure     => present,
    options    => ['GRANT'],
    privileges => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
    table      => '`phabricator_%`.*',
    user       => "${phabricator::config::user}@phabricator.${::domain}",
    require    => Class['mysql::server'],
  }

  exec { 'storage-upgrade':
    command   => "${phabricator::config::base_dir}/phabricator/bin/storage upgrade --force",
    logoutput => true,
    unless    => "${phabricator::config::base_dir}/phabricator/bin/storage status",
    require   => [
      Class['phabricator::install'],
      Class['mysql::server'],
    ],
    subscribe => Vcsrepo["${phabricator::config::base_dir}/phabricator"],
  }
}
