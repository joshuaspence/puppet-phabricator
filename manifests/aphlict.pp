# Class for installing Aphlict.
#
# @summary This class manages Aphlict, Phabricator's real-time notifications
# service. See
# {https://secure.phabricator.com/book/phabricator/article/notifications/
# Notifications User Guide: Setup and Configuration}.
#
# @param servers A list of servers to start. See
#   {https://secure.phabricator.com/book/phabricator/article/notifications/#running-the-aphlict-serv
#   Running the Aphlict Server}.
# @param peers A list of cluster peers. See
#   {https://secure.phabricator.com/book/phabricator/article/cluster_notifications/#configuring-aphlict
#   Configuring Aphlict}.
# @param user
#
class phabricator::aphlict(
  Array[Phabricator::Aphlict::Server] $servers,
  Array[Phabricator::Aphlict::Peer]   $peers,
  String                              $user,
) {
  $config = {
    servers => $servers,
    logs    => [
      {
        path => "${phabricator::logs_dir}/aphlict.log",
      },
    ],
    cluster => $peers,
    pidfile => "${phabricator::pid_dir}/aphlict.pid",
  }

  file { 'phabricator/conf/aphlict.json':
    ensure  => 'file',
    path    => "${phabricator::install_dir}/phabricator/conf/aphlict/aphlict.custom.json",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service['aphlict'],
    require => Vcsrepo['phabricator'],

    # TODO: Use an EPP template instead of an ERB template.
    content => inline_template('<%= @config.to_json %>');
  }

  user { $user:
    ensure     => 'present',
    comment    => 'Phabricator Aphlict',
    gid        => $phabricator::group,
    home       => $phabricator::pid_dir,
    managehome => false,
    shell      => '/usr/sbin/nologin',
    system     => true,
  }

  include nodejs

  nodejs::npm { 'ws':
    ensure  => 'present',
    target  => "${phabricator::install_dir}/phabricator/support/aphlict/server",
    notify  => Service['aphlict'],
    require => Vcsrepo['phabricator'],
  }

  # TODO: The `strict_indent` check doesn't seem to work properly here. See
  # https://github.com/relud/puppet-lint-strict_indent-check/issues/11.
  #
  # lint:ignore:strict_indent
  systemd::unit_file { 'aphlict.service':
    ensure  => 'file',
    content => epp('phabricator/aphlict.systemd.epp', {
      command => "${phabricator::install_dir}/phabricator/bin/aphlict",
      user    => $user,
      group   => $phabricator::group,
    }),
    notify  => Service['aphlict'],
  }
  # lint:endignore

  # TODO: Should we also specify `hasrestart => true`? According to the
  # documentation the default value is `false`, although I am somewhat
  # surprised by this.
  service { 'aphlict':
    ensure    => 'running',
    enable    => true,
    require   => [
      Class['php::cli'],
      Exec['systemctl-daemon-reload'],
      File[$phabricator::logs_dir],
      File[$phabricator::pid_dir],
      Group[$phabricator::group],
      User[$user],
      Vcsrepo['arcanist'],
    ],
    subscribe => [
      Class['nodejs::install'],
      Vcsrepo['libphutil'],
      Vcsrepo['phabricator'],
    ],
  }

  logrotate::rule { 'aphlict':
    ensure        => 'present',
    path          => "${phabricator::logs_dir}/aphlict.log",
    compress      => true,
    copytruncate  => true,
    delaycompress => true,
    ifempty       => false,
    missingok     => true,
    rotate        => 7,
    rotate_every  => 'day',
    su_owner      => 'root',
    su_group      => $phabricator::group,
  }
}
