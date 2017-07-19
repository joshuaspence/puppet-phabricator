# Configures Phabricator.
#
# @summary Configures Arcanist, libphutil and Phabricator.
# @private
#
class phabricator::config {
  assert_private()

  group { $phabricator::group:
    ensure => 'present',
    system => true,
  }

  user {
    default:
      ensure     => 'present',
      gid        => $phabricator::group,
      managehome => false,
      system     => true;

    $phabricator::daemon_user:
      comment => 'Phabricator Daemons',
      home    => "${phabricator::install_dir}/phabricator/support/empty",
      shell   => '/usr/sbin/nologin';

    $phabricator::vcs_user:
      comment => 'Phabricator VCS',
      home    => $phabricator::repo_dir,
      shell   => '/bin/sh';
  }

  file {
    default:
      owner => 'root',
      group => $phabricator::group;

    $phabricator::logs_dir:
      ensure => 'directory',
      mode   => '0775';

    $phabricator::pid_dir:
      ensure => 'directory',
      mode   => '0775';

    $phabricator::repo_dir:
      ensure => 'directory',
      owner  => $phabricator::daemon_user,
      mode   => '0750';

    'phabricator/conf/local.json':
      ensure  => 'file',
      path    => "${phabricator::install_dir}/phabricator/conf/local/local.json",
      mode    => '0640',
      require => Vcsrepo['phabricator'],

      # TODO: Use an EPP template instead of an ERB template.
      content => inline_template("<%= scope['phabricator::config'].to_json %>");
  }

  if $phabricator::storage_upgrade {
    $storage_upgrade_flags = shellquote(
      [
        '--force',
        "--user=${phabricator::storage_upgrade_user}",
        "--password=${phabricator::storage_upgrade_password}",
      ]
    )

    # TODO: We should possibly use `onlyif` or `unless` instead of `refreshonly`.
    exec { 'bin/storage upgrade':
      command     => "${phabricator::install_dir}/phabricator/bin/storage upgrade ${storage_upgrade_flags}",
      refreshonly => true,
      timeout     => 0,
      require     => [
        Class['php::cli'],
        File['phabricator/conf/local.json'],
        Php::Extension['mysql'],
        Vcsrepo['arcanist'],
        Vcsrepo['libphutil'],
      ],
      subscribe   => Vcsrepo['phabricator'],
    }
  }

  # TODO: We should be able to tighten these permissions as follows:
  #
  # - `/usr/bin/git`, `/usr/bin/git-receive-pack`, `/usr/bin/git-upload-pack`
  #   and `/usr/lib/git-core/git-http-backend` should only be required if the
  #   node is //hosting// Diffusion repositories.
  # - `/usr/bin/ssh` should only be required if the node is //serving// (either
  #   directly or by proxy) Diffusion repositories.
  #
  if $phabricator::manage_diffusion {
    # lint:ignore:strict_indent
    sudo::conf { "${phabricator::vcs_user}:${phabricator::daemon_user}":
      ensure  => 'present',
      content => sprintf(
        '%s ALL=(%s) SETENV: NOPASSWD: %s',
        $phabricator::vcs_user,
        "${phabricator::daemon_user}:${phabricator::group}",
        join([
          '/usr/bin/git',
          '/usr/bin/git-receive-pack',
          '/usr/bin/git-upload-pack',
          '/usr/bin/ssh',
        ], ', '),
      ),
    }
    # lint:endignore

    # TODO: This is dirty, but otherwise `$php::fpm` may not be defined.
    include php

    if $php::fpm {
      include php::params

      # lint:ignore:strict_indent
      sudo::conf { "${php::params::fpm_user}:${phabricator::daemon_user}":
        ensure  => 'present',
        content => sprintf(
          '%s ALL=(%s) SETENV: NOPASSWD: %s',
          $php::params::fpm_user,
          "${phabricator::daemon_user}:${phabricator::group}",
          join([
            '/usr/bin/git',
            '/usr/bin/ssh',
            '/usr/lib/git-core/git-http-backend',
          ], ', '),
        ),
      }
      # lint:endignore
    }

    # lint:ignore:strict_indent
    ssh::server::config::setting { $phabricator::vcs_user:
      key   => "Match User ${phabricator::vcs_user}",

      # TODO: This seems quite hacky.
      value => join([
        '',
        "AuthorizedKeysCommand ${phabricator::install_dir}/phabricator/bin/ssh-auth",
        "AuthorizedKeysCommandUser ${phabricator::vcs_user}",
      ], "\n  "),
    }
    # lint:endignore

  }
}
