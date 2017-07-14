# Changelog

## 0.5.2

## Features

- Allow `--identify-as` to be passed to `bin/almanac register`.

## 0.5.1

### Bug Fixes

- Change the home directory for the daemon user to be `/nonexistent`.

## 0.5.0

### Breaking Changes

- The repository directory (`/var/repo` by default) is, once again, managed by
  this module. This is a revert of #8.
- The Almanac device key (`/usr/local/src/phabricator/conf/keys/device.key`) is
  no longer group-readable.
- This module now overrides the configuration value for
  `environment.append-paths`.

### Features

- Added a `logrotate` rule for Aphlict (#12).
- Added support for Diffusion repository hosting (#14). This functionality is
  disabled by default, but can be enabled with `$phabricator::manage_diffusion`.

### Bug Fixes

- The daemon user (`phd`) is now created unconditionally (#11). Previously,
  this user would only be created if Phabricator daemons were configured on the
  host. It was discovered that there are other cases in which the daemon user
  may be required and, as such, it was decided to simply create the daemon user
  unconditionally.
- Added `/usr/lib/git-core` to `environment.append-paths` so that
  `git-http-backend` works.

### Improvements

- Refactor unit tests.

## 0.4.0

### Breaking Changes

- The default value for `$vcs_user` has been changed from `vcs` to `diffusion`
  (#10).
- The repository directory (`/var/repo` by default) is no longer managed by
  this module (#8). Instead, this directory should be created by
  `PhabricatorRepositoryPullLocalDaemon`. Consequently, the `$repo_dir`
  parameter has also been removed.

### Features

- Marked internal classes as private using [`assert_private`](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private).
- Documentation improvements.
- Officially support Puppet 5 (#9).

### Bug Fixes

- Ensure that `./bin/almanac register` is executed before the `phd` service is
  started (#7).

## 0.3.4

### Bug Fixes

- Fixes the `systemd` unit file for the `phd` service, which was broken in
  v0.3.3.

## 0.3.3 (deleted)

### Features

- Added support for registering [Almanac devices][almanac] (#4).
- The `$config_hash` parameter is now deep-merged by default.
- Added support for launching a specific Phabricator daemon using `./bin/phd
  launch` (#5).

## 0.3.2

### Features

- Added support for managing [Aphlict][aphlict], Phabricator's real-time
  notifications service (#3).

### Bug Fixes

- Added a warning if the installed PHP version is incompatible with Phabricator
  (#2).

## 0.3.1

### Features

- Added support for managing [Phabricator daemons][phd] (#1).

## 0.3.0

### Summary

This is a major rewrite which involved completely throwing away the old code
and starting again from scratch. The rewritten module has comprehensive unit
tests (with [`rspec-puppet`](http://rspec-puppet.com)) and acceptance tests
(with [`beaker-rspec`](https://github.com/puppetlabs/beaker-rspec)).

[almanac]: https://secure.phabricator.com/book/phabricator/article/almanac/
[aphlict]: https://secure.phabricator.com/book/phabricator/article/notifications/
[phd]: https://secure.phabricator.com/book/phabricator/article/managing_daemons/
