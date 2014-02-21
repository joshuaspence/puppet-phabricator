# == Define: phabricator::web
#
class phabricator::web (
  $domain = $::domain,
) {

  validate_string($domain)

  include '::phabricator::install'

  file { "${phabricator::config::base_dir}/phabricator/conf/local/local.json":
    ensure  => present,
    content => template('phabricator/config.json.erb'),
    require => Vcsrepo["${phabricator::config::base_dir}/phabricator"],
  }

  class { 'nginx':
    worker_processes => 'auto',
    confd_purge      => true,
    server_tokens    => 'off',
    http_cfg_append  => {
      'charset'         => 'UTF-8',
      'gzip'            => 'on',
      'gzip_comp_level' => '4',
      'gzip_proxied'    => 'any',
      'gzip_static'     => 'on',
      'gzip_types'      => 'application/javascript application/json application/rss+xml application/vnd.ms-fontobject application/xhtml+xml application/xml application/xml+rss application/x-font-opentype application/x-font-ttf application/x-javascript image/svg+xml image/x-icon text/css text/javascript text/plain text/xml',
      'gzip_vary'       => 'on',
      'tcp_nopush'      => 'on',
    }
  }
  nginx::resource::vhost { "phabricator.${domain}":
    ensure               => 'present',
    index_files          => ['index.php'],
    www_root             => "${phabricator::config::base_dir}/phabricator/webroot",
    access_log           => '/var/log/nginx/phabricator-access.log',
    error_log            => '/var/log/nginx/phabricator-error.log',
    use_default_location => false,
  }
  nginx::resource::location { "phabricator.${domain}/":
    ensure        => 'present',
    location      => '/',
    vhost         => "phabricator.${domain}",
    www_root      => "${phabricator::config::base_dir}/phabricator/webroot",
    index_files   => [],
    rewrite_rules => [
      '^/(.*)$ /index.php?__path__=/$1 last',
    ],
  }
  nginx::resource::location { "phabricator.${domain}/rsrc/":
    ensure              => 'present',
    location            => '/rsrc/',
    vhost               => "phabricator.${domain}",
    location_custom_cfg => {
      try_files => '$uri $uri/ =404',
    },
  }
  nginx::resource::location { "phabricator.${domain}/favicon.ico":
    ensure              => 'present',
    location            => '= /favicon.ico',
    vhost               => "phabricator.${domain}",
    location_custom_cfg => {
      try_files => '$uri =204',
    },
  }
  nginx::resource::location { "phabricator.${domain}/~.php":
    ensure              => 'present',
    location            => '~ .php$',
    vhost               => "phabricator.${domain}",
    fastcgi             => 'phabricator_rack_app',
    location_cfg_append => {
      'fastcgi_index' => 'index.php',
      'fastcgi_param' => "PHABRICATOR_ENV '${phabricator::config::environment}'",
    },
  }
  nginx::resource::upstream { 'phabricator_rack_app':
    ensure  => present,
    members => [
      'unix:/var/run/php5-fpm.socket',
    ],
  }

  nginx::resource::vhost { 'monitor':
    ensure               => 'present',
    listen_ip            => '127.0.0.1',
    listen_port          => '8080',
    location_allow       => ['127.0.0.1'],
    index_files          => [],
    access_log           => '/var/log/nginx/localhost-access.log',
    error_log            => '/var/log/nginx/localhost-error.log',
    use_default_location => false,
  }
  nginx::resource::location { 'monitor/ping':
    ensure   => 'present',
    location => '/ping',
    vhost    => 'monitor',
    fastcgi  => 'phabricator_rack_app',
  }
  nginx::resource::location { 'monitor/status':
    ensure   => 'present',
    location => '/status',
    vhost    => 'monitor',
    fastcgi  => 'phabricator_rack_app',
  }

  php::module { ['apc', 'curl', 'gd']: }
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
    ensure               => present,
    listen               => '/var/run/php5-fpm.socket',
    user                 => 'nginx',
    pm_status_path       => '/status',
    ping_path            => '/ping',
    catch_workers_output => 'yes',
    env                  => ['PATH'],
    php_value            => {
      date_timezone => 'UTC',
    },
    require              => [
      Class['nginx'],
      Php::Module['mysql'],
    ],
  }
  class { 'php::fpm::daemon': }

  package { 'imagemagick':
    ensure => installed,
  }

  package { 'python-pygments':
    ensure => installed,
  }
}
