# == Class: phabricator::daemon
#
# This module manages the Phabricator Daemon (phd).
#
# === Parameters
#
# [*service_ensure*]
#
# === Variables
#
# === Examples
#
class phabricator::daemon(
  $service_ensure = 'running',
) {

  include '::phabricator::install'

  validate_string($service_ensure)
  if ! ($service_ensure in ['stopped', 'running']) {
    fail('service_ensure parameter must be "stopped" or "running"')
  }

  file { ['/var/tmp/phd',
          '/var/tmp/phd/pid',
          '/var/tmp/phd/log']:
    ensure => directory,
    owner  => $phabricator::config::user,
    group  => $phabricator::config::group,
  }

  file { '/etc/init.d/phd':
    ensure  => present,
    mode    => '0755',
    content => template('phabricator/phd.erb'),
  }

  service { 'phd':
    ensure     => $service_ensure,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      Class['phabricator::install'],
      File['/etc/init.d/phd'],
    ],
    subscribe  => [
      Vcsrepo["${phabricator::config::base_dir}/libphutil"],
      Vcsrepo["${phabricator::config::base_dir}/phabricator"],
    ],
  }
}
