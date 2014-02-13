# == Define: phabricator::db
#
class phabricator::db {
  include phabricator::install

  if ! ($environment in ['development', 'production']) {
    fail('environment parameter must be "development" or "production"')
  }

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

  exec { 'phd-start':
    command   => '/usr/src/phabricator/bin/phd start',
    logoutput => true,
    require   => [
      Class['phabricator::install'],
      Class['php::cli'],
      Exec['storage-upgrade'],
    ],
  }
}
