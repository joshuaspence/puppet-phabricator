# Class: phabricator::params
#
# This module manages the default Phabricator parameters.
#
# Parameters:
#
# Actions:
#
# Requires:
#
class phabricator::params {
  $base_dir    = '/usr/src'
  $environment = 'production'
  $user        = 'phabricator'
  $group       = 'phabricator'
}
