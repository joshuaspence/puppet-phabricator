# == Define: phabricator::db
#
class phabricator::db {
  include phabricator::install

  case $phabricator::config::environment {
    'production': {
      $mysql_override = {}
    }
    default: {
      $mysql_override = {
        'mysqld' => {
          'sql-mode' => 'STRICT_ALL_TABLES',
        },
      }
    }
  }

  class { 'mysql::server':
    override_options => $mysql_override,
  }

  exec { 'storage-upgrade':
    command   => '/usr/src/phabricator/bin/storage upgrade --force',
    logoutput => true,
    unless    => '/usr/src/phabricator/bin/storage status',
    require   => [
      Class['phabricator::install'],
      Class['mysql::server'],
    ],
    subscribe => Vcsrepo['/usr/src/phabricator'],
  }
}
