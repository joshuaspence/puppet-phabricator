# == Define: phabricator
#
class phabricator (
  $environment = $phabricator::params::environment,
) inherits phabricator::params {

  validate_string($environment)
  if ! ($environment in ['development', 'production']) {
    fail('environment parameter must be "development" or "production"')
  }

  class { 'phabricator::config':
    environment => $environment,
  }
}
