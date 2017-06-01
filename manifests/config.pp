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
}
