# == Define: phabricator::config
#
# This module manages Phabricator configuration.
#
class phabricator::config (
  $base_dir    = $phabricator::params::base_dir,
  $environment = $phabricator::params::environment,
) inherits phabricator::params {

  file { $base_dir:
    ensure => directory,
  }
}
