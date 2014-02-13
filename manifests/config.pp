# == Define: phabricator::config
#
class phabricator::config (
  $base_dir    = $phabricator::params::base_dir,
  $environment = $phabricator::params::environment,
) {}
