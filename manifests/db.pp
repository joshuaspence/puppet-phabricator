# == Define: phabricator::db
#
class phabricator::db {
  include phabricator::install

  class { 'mysql::server': }

  exec { 'storage-upgrade':
    command => '/usr/src/phabricator/bin/storage upgrade --force',
    unless  => '/usr/src/phabricator/bin/storage status',
    require => [
      Class['phabricator::install'],
      Class['mysql::server'],
    ],
  }
}
