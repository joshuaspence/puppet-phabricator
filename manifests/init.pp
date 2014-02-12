# == Define: phabricator
#
class phabricator (
  $environment = $phabricator::params::environment,
) inherits phabricator::params {

  validate_string($environment)

  class { 'phabricator::config':
    environment => $environment,
  }
}
