# == Define: phabricator::install
#
class phabricator::install {
  include phabricator

  vcsrepo { '/usr/src/arcanist':
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/arcanist.git',
    require  => Class['php::cli'],
  }
  vcsrepo { '/usr/src/libphutil':
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/libphutil.git',
    require  => Class['php::cli'],
  }
  vcsrepo { '/usr/src/phabricator':
    ensure   => latest,
    provider => git,
    source   => 'git://github.com/facebook/phabricator.git',
    require  => Class['php::cli'],
  }

  exec { 'build_xhpast':
    command   => '/usr/src/libphutil/scripts/build_xhpast.sh',
    logoutput => true,
    subscribe => Vcsrepo['/usr/src/libphutil'],
    require   => [
      Package['g++'],
      Package['make'],
      Class['php::cli'],
    ]
  }
}
