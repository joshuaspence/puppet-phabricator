# Class for registering an Almanac device.
#
# @summary This class can be used to register an Almanac device using
# `./bin/almanac register`. See the
# {https://secure.phabricator.com/book/phabricator/article/almanac/
# Almanac User Guide} for further information.
#
# @param device The name of the Almanac device to register.
# @param identity The name of the Almanac device to identify as.
# @param private_key The contents of an SSH private key that has been associated
#   with the specified Almanac device. This SSH key must be manually marked as
#   trusted using the `./bin/almanac trust-key` command.
#
class phabricator::almanac(
  String $device,
  Optional[String] $identity,
  String $private_key,
) {
  $device_id_path   = "${phabricator::install_dir}/phabricator/conf/keys/device.id"
  $private_key_path = "${phabricator::install_dir}/phabricator/conf/keys/device.key"

  file { 'phabricator/conf/device.key':
    ensure  => 'file',
    path    => $private_key_path,
    content => $private_key,
    owner   => $phabricator::daemon_user,
    group   => $phabricator::group,
    mode    => '0400',
    notify  => Exec['almanac register'],
    require => Vcsrepo['phabricator'],
  }

  $_options = [
    "--device ${device}",
    '--force',
    "--private-key ${private_key_path}",
  ]

  if $identity == undef {
    $identity_option = undef
  } else {
    $identity_option = "--identify-as ${identity}"
  }

  $options = delete_undef_values(concat($_options, [$identity_option]))

  # TODO: The `strict_indent` check doesn't seem to work properly here. See
  # https://github.com/relud/puppet-lint-strict_indent-check/issues/11.
  #
  # lint:ignore:strict_indent
  exec { 'almanac register':
    command => "${phabricator::install_dir}/phabricator/bin/almanac register ${join($options, ' ')}",
    creates => $device_id_path,
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

  # TODO: This is dirty, but there's no way that we can accurately determine
  # whether `Class[phabricator::daemons]` exists in the catalogue. I think that
  # the solution here is to make the `phabricator::almanac` and
  # `phabricator::daemons` classes private (using `assert_private()`), and to
  # instead use flags to determine whether these classes should be included
  # (e.g. `$phabricator::almanac = true` and `$phabricator::daemons = true`).
  Exec['almanac register'] -> Service <| title == 'phd' |>
}
