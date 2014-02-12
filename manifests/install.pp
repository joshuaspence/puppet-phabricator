# == Define: phabricator::install
#
class phabricator::install {
  package { ['git', 'g++', 'make']:
    ensure => installed,
  }

  php::ini { '/etc/php.ini': }
  class { 'php::cli':
    ensure  => installed,
    inifile => '/etc/php.ini',
  }

  vcsrepo { "${phabricator::config::base_dir}/arcanist":
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/arcanist.git',
    require  => Class['php::cli'],
  }
  vcsrepo { "${phabricator::config::base_dir}/libphutil":
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/libphutil.git',
    require  => Class['php::cli'],
    notify   => Exec['build_xhpast'],
  }
  vcsrepo { "${phabricator::config::base_dir}/phabricator":
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/phabricator.git',
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
