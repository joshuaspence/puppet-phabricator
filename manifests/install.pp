# Installs Phabricator.
#
# @summary Installs Arcanist, libphutil and Phabricator.
# @private
#
class phabricator::install {
  assert_private()

  # The `php::packages` class requires `Class['apt::update']` unconditionally,
  # but the `apt::update` class may not have been defined. See
  # https://github.com/voxpupuli/puppet-php/pull/323.
  include apt
  include git
  include php

  if $php::fpm {
    $notify = Class['php::fpm::service']
  } else {
    $notify = []
  }

  php::extension {
    'apcu':
      package_prefix => 'php-';

    ['curl', 'gd', 'mbstring']: ;

    'mysql':
      so_name => 'mysqli';
  }

  vcsrepo {
    default:
      ensure   => 'latest',
      provider => 'git',
      notify   => $notify;

    'arcanist':
      path     => "${phabricator::install_dir}/arcanist",
      source   => 'https://github.com/phacility/arcanist.git',
      revision => $phabricator::arcanist_revision;

    'libphutil':
      path     => "${phabricator::install_dir}/libphutil",
      source   => 'https://github.com/phacility/libphutil.git',
      revision => $phabricator::libphutil_revision;

    'phabricator':
      path     => "${phabricator::install_dir}/phabricator",
      source   => 'https://github.com/phacility/phabricator.git',
      revision => $phabricator::phabricator_revision;
  }

  # These packages are required in order to compile XHPAST.
  ensure_packages(['g++', 'make'])

  exec { 'build_xhpast.php':
    command     => "${phabricator::install_dir}/libphutil/scripts/build_xhpast.php",
    refreshonly => true,
    require     => [
      Class['php::cli'],
      Package['g++'],
      Package['make'],
    ],
    subscribe   => Vcsrepo['libphutil'],
  }

  if $phabricator::install_fonts {
    debconf { 'msttcorefonts/accepted-mscorefonts-eula':
      ensure  => 'present',
      package => 'ttf-mscorefonts-installer',
      type    => 'select',
      value   => bool2str(true),
      before  => Package['ttf-mscorefonts-installer'],
    }

    package { 'ttf-mscorefonts-installer':
      ensure  => 'latest',
    }

    $font_file_ensure = 'link'
  } else {
    $font_file_ensure = 'absent'
  }

  file { "${phabricator::install_dir}/phabricator/resources/font/impact.ttf":
    ensure  => $font_file_ensure,
    target  => '/usr/share/fonts/truetype/msttcorefonts/Impact.ttf',
    require => Vcsrepo['phabricator'],
  }
}
