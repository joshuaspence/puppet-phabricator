# Class: phabricator::db
#
# This module manages the Phabricator Database.
#
# Parameters:
#
# Actions:
#
# Requires:
#
class phabricator::db {
  include '::phabricator::install'

  if ! ($environment in ['development', 'production']) {
    fail('environment parameter must be "development" or "production"')
  }

  case $phabricator::config::environment {
    'production': {
      $mysql_override = {
        'mysqld' => {
          'bind-address' => $::ipaddress_eth1,
        },
      }
    }
    default: {
      $mysql_override = {
        'mysqld' => {
          'bind-address' => $::ipaddress_eth1,
          'sql-mode' => 'STRICT_ALL_TABLES',
        },
      }
    }
  }

  class { 'mysql::server':
    override_options        => $mysql_override,
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
