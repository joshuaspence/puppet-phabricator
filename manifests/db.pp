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
