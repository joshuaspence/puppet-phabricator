# == Define: phabricator::params
#
# This module manages Phabricator parameters.
#
class phabricator::params {
  $base_dir    = '/usr/src'
  $environment = 'production'
  $user        = 'phabricator'
  $group       = 'phabricator'
}
