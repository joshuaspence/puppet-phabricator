# Class for registering an Almanac device.
#
# @summary This class can be used to register an Almanac device using
# `./bin/almanac register`. See the
# {https://secure.phabricator.com/book/phabricator/article/almanac/
# Almanac User Guide} for further information.
#
# @param device The name of the Almanac device to register.
# @param private_key The contents of an SSH private key that has been associated
#   with the specified Almanac device. This SSH key must be manually marked as
#   trusted using the `./bin/almanac trust-key` command.
#
class phabricator::almanac(
  String $device,
  String $private_key,
) {
  $device_id_path   = "${phabricator::install_dir}/phabricator/conf/keys/device.id"
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
    command => join([
      "${phabricator::install_dir}/phabricator/bin/almanac register",
      "--device ${device}",
      '--force',
      "--private-key ${private_key_path}",
    ], ' '),
    creates => $device_id_path,
    before  => Service['phd'],
    require => [
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
