# == Define: phabricator::daemon::launch
#
# This module launch an individual Phabricator Daemon (phd).
#
# === Parameters
#
# [*daemon*]
# [*arguments*]
#
# === Variables
#
# === Examples
#
define phabricator::daemon::launch(
  $daemon = $name,
  $arguments = [],
) {

  include '::phabricator::install'

  validate_string($daemon)
  validate_array($arguments)

  if (size($arguments)) {
    $joined_args = join($arguments, ' ')
    $args = "-- ${joined_args}"
  } else {
    $args = ''
  }

  service { "phd-launch-${daemon}":
    ensure     => running,
    binary     => "${phabricator::config::base_dir}/phabricator/bin/phd",
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    provider   => 'base',
    start      => "${phabricator::config::base_dir}/phabricator/bin/phd launch ${daemon} ${args}",
    require    => [
      Class['phabricator::daemon'],
      Class['phabricator::install'],
    ],
    subscribe  => [
      Vcsrepo["${phabricator::config::base_dir}/libphutil"],
      Vcsrepo["${phabricator::config::base_dir}/phabricator"],
    ],
  }
}
