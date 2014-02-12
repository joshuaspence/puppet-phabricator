# == Define: phabricator
#
class phabricator {
  package { ['git', 'g++', 'make']:
    ensure => installed,
  }

  class { 'php::cli':
    ensure => installed,
  }
  php::ini { '/etc/php.ini': }
}
