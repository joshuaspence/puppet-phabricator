# == Define: phabricator::web
#
class phabricator::web {
  include phabricator::install

  class { 'nginx': }
  nginx::resource::vhost { 'phabricator.joshuaspence.com':
    ensure               => 'present',
    index_files          => ['index.php'],
    www_root             => '/usr/src/phabricator/webroot',
    access_log           => '/var/log/access.log',
    error_log            => '/var/log/error.log',
    use_default_location => false,
  }
  nginx::resource::location { 'phabricator.joshuaspence.com/':
    ensure        => 'present',
    location      => '/',
    vhost         => 'phabricator.joshuaspence.com',
    www_root      => '/usr/src/phabricator/webroot',
    index_files   => [],
    rewrite_rules => [
      '^/(.*)$ /index.php?__path__=/$1 last',
    ],
  }
  nginx::resource::location { 'phabricator.joshuaspence.com/rsrc/':
    ensure              => 'present',
    location            => '/rsrc/',
    vhost               => 'phabricator.joshuaspence.com',
    location_custom_cfg => {
      try_files => '$uri $uri/ =404',
    },
  }
  nginx::resource::location { 'phabricator.joshuaspence.com/favicon.ico':
    ensure              => 'present',
    location            => '= /favicon.ico',
    vhost               => 'phabricator.joshuaspence.com',
    location_custom_cfg => {
      try_files => '$uri =204',
    },
  }
  nginx::resource::location { 'phabricator.joshuaspence.com/~.php':
    ensure              => 'present',
    location            => '~ .php$',
    vhost               => 'phabricator.joshuaspence.com',
    fastcgi             => 'localhost:9000',
    location_cfg_append => {
      'fastcgi_index' => 'index.php',
      'fastcgi_param' => 'PHABRICATOR_ENV "production"',
    },
  }

  php::module { ['apc', 'curl', 'gd', 'mysql']: }

  php::fpm::conf { 'www':
    listen  => '127.0.0.1:9000',
    user    => 'nginx',
    require => [
      Class['nginx'],
      Php::Module['mysql'],
    ],
  }
  class { 'php::fpm::daemon': }

  exec { 'phd-start':
    command => '/usr/src/phabricator/bin/phd start',
    require => [
      Class['phabricator::install'],
      Class['php::cli'],
      Exec['storage-upgrade'],
    ],
  }
}
