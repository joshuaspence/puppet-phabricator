# == Define: phabricator::web
#
class phabricator::web (
  $hostname = undef,
) {

  validate_string($hostname)

  include phabricator::install

  class { 'nginx':
    worker_processes => 'auto',
    http_cfg_append  => {
      'tcp_nopush' => 'on',
    }
  }
  nginx::resource::vhost { $hostname:
    ensure               => 'present',
    index_files          => ['index.php'],
    www_root             => "${phabricator::config::base_dir}/phabricator/webroot",
    access_log           => '/var/log/access.log',
    error_log            => '/var/log/error.log',
    use_default_location => false,
  }
  nginx::resource::location { "${hostname}/":
    ensure        => 'present',
    location      => '/',
    vhost         => $hostname,
    www_root      => "${phabricator::config::base_dir}/phabricator/webroot",
    index_files   => [],
    rewrite_rules => [
      '^/(.*)$ /index.php?__path__=/$1 last',
    ],
  }
  nginx::resource::location { "${hostname}/rsrc/":
    ensure              => 'present',
    location            => '/rsrc/',
    vhost               => $hostname,
    location_custom_cfg => {
      try_files => '$uri $uri/ =404',
    },
  }
  nginx::resource::location { "${hostname}/favicon.ico":
    ensure              => 'present',
    location            => '= /favicon.ico',
    vhost               => $hostname,
    location_custom_cfg => {
      try_files => '$uri =204',
    },
  }
  nginx::resource::location { "${hostname}/~.php":
    ensure              => 'present',
    location            => '~ .php$',
    vhost               => $hostname,
    fastcgi             => 'localhost:9000',
    location_cfg_append => {
      'fastcgi_index' => 'index.php',
      'fastcgi_param' => "PHABRICATOR_ENV '${phabricator::config::environment}'",
    },
  }

  php::module { ['apc', 'curl', 'gd', 'mysql']: }
  case $environment {
    'production': {
      $apc_settings = {
        'apc.stat' => '0',
      }
    }
    default: {
      $apc_settings = {
        'apc.stat' => '1',
      }
    }
  }
  php::module::ini { 'apc':
    settings => $apc_settings,
  }

  php::fpm::conf { 'www':
    ensure    => present,
    listen    => '127.0.0.1:9000',
    user      => $nginx::params::nx_daemon_user,
    env       => ['PATH'],
    php_value => {
      date_timezone => 'UTC',
    },
    require   => [
      Class['nginx'],
      Php::Module['mysql'],
    ],
  }
  class { 'php::fpm::daemon': }
}
