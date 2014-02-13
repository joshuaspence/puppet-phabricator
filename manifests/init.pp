# == Define: phabricator
#
class phabricator (
  $environment = $phabricator::params::environment,
) inherits phabricator::params {

  validate_string($environment)

  class { 'phabricator::config':
    environment => $environment,
  }

  package { ['git', 'g++', 'make']:
    ensure => installed,
  }

  class { 'php::cli':
    ensure => installed,
  }
  php::ini { '/etc/php.ini': }
}
