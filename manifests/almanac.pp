# Class for registering an Almanac device.
#
# @param device
# @param private_key
#
class phabricator::almanac(
  String $device,
  String $private_key,
) {
  $private_key_path = "${phabricator::install_dir}/phabricator/conf/keys/device.key"

  file { 'phabricator/conf/device.key':
    ensure  => 'file',
    path    => $private_key_path,
    content => $private_key,
    owner   => $phabricator::daemon_user,
    group   => 'root',
    mode    => '0400',
    notify  => Exec['almanac register'],
    require => Vcsrepo['phabricator'],
  }

  # TODO: The `strict_indent` check doesn't seem to work properly here. See
  # https://github.com/relud/puppet-lint-strict_indent-check/issues/11.
  #
  # lint:ignore:strict_indent
  exec { 'almanac register':
    command     => join([
      "${phabricator::install_dir}/phabricator/bin/almanac register",
      "--device ${device}",
      '--force',
      "--private-key ${private_key_path}",
    ], ' '),
    refreshonly => true,
    require     => [
      Class['php::cli'],
      File['phabricator/conf/local.json'],
      Php::Extension['mysql'],
      Vcsrepo['libphutil'],
      Vcsrepo['phabricator'],
    ],
  }
  # lint:endignore

  if $phabricator::storage_upgrade {
    Exec['bin/storage upgrade'] -> Exec['almanac register']
  }
}
