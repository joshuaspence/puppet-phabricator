# == Define: phabricator
#
class phabricator {
  include git

  package { ['g++', 'make']:
    ensure => installed,
  }

  class { 'php::cli':
    ensure => installed,
  }
  php::ini { '/etc/php.ini': }
}
