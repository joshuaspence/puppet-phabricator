# == Define: phabricator
#
class phabricator (
  $base_dir    = $phabricator::params::base_dir,
  $environment = $phabricator::params::environment,
) inherits phabricator::params {

  validate_absolute_path($base_dir)

  validate_string($environment)
  if ! ($environment in ['development', 'production']) {
    fail('environment parameter must be "development" or "production"')
  }

  class { 'phabricator::config':
    environment => $environment,
  }
}
