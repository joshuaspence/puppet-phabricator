# Class: phabricator::install
#
# This module installs Phabricator dependencies.
#
# Parameters:
#
# Actions:
#
# Requires:
#
class phabricator::install {
  package { ['git', 'g++', 'make']:
    ensure => installed,
  }

  php::ini { '/etc/php.ini':
    date_timezone => 'UTC',
  }
  class { 'php::cli':
    ensure  => installed,
    inifile => '/etc/php.ini',
  }
  php::module { ['mysql']: }

  vcsrepo { "${phabricator::config::base_dir}/arcanist":
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/arcanist.git',
    owner    => $phabricator::config::user,
    group    => $phabricator::config::group,
    require  => Class['php::cli'],
  }
  vcsrepo { "${phabricator::config::base_dir}/libphutil":
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/libphutil.git',
    owner    => $phabricator::config::user,
    group    => $phabricator::config::group,
    require  => Class['php::cli'],
    notify   => Exec['build_xhpast'],
  }
  vcsrepo { "${phabricator::config::base_dir}/phabricator":
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/phabricator.git',
    owner    => $phabricator::config::user,
    group    => $phabricator::config::group,
    require  => Class['php::cli'],
  }

  exec { 'build_xhpast':
    command   => "${phabricator::config::base_dir}/libphutil/scripts/build_xhpast.sh",
    logoutput => true,
    subscribe => Vcsrepo["${phabricator::config::base_dir}/libphutil"],
    require   => [
      Package['g++'],
      Package['make'],
      Class['php::cli'],
    ]
  }
}
