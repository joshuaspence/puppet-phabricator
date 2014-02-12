# == Define: phabricator::db
#
class phabricator::db (
  $environment = 'production',
) {
  validate_string($environment)

  include phabricator::install

  class { 'mysql::server': }

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
