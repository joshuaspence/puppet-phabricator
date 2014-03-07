# == Class: phabricator::aphlict
#
# This module manages the Phabricator notifications server.
#
# === Parameters
#
# === Variables
#
# === Examples
#
class phabricator::aphlict {
  include '::phabricator::install'

  class { 'nodejs': }

  exec { 'aphlict':
    command   => "${phabricator::config::base_dir}/phabricator/bin/aphlict",
    logoutput => true,
    subscribe => Vcsrepo["${phabricator::config::base_dir}/phabricator"],
    require   => [
      Class['nodejs'],
    ]
  }
}
