# == Class: phabricator::config
#
# This module manages Phabricator configuration.
#
# === Parameters
#
# [*base_dir*]
# [*environment*]
# [*user*]
# [*group*]
#
# === Variables
#
# === Examples
#
class phabricator::config (
  $base_dir    = $phabricator::params::base_dir,
  $environment = $phabricator::params::environment,
  $user        = $phabricator::params::user,
  $group       = $phabricator::params::group,
) inherits phabricator::params {

  file { $base_dir:
    ensure => directory,
  }

  user { $user:
    ensure  => present,
    comment => 'Phabricator user',
    gid     => $group,
  }

  group { $group:
    ensure  => present,
  }
}
