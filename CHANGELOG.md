# Changelog

## 0.3.3

### Features

- Added support for registering [Almanac devices][almanac].
- The `$config_hash` parameter is now deep-merged by default.

## 0.3.2

### Features

- Added support for managing [Aphlict][aphlict], Phabricator's real-time
  notifications service.

### Bug Fixes

- Added a warning if the installed PHP version is incompatible with Phabricator.

## 0.3.1

### Features

- Added support for managing [Phabricator daemons][phd].

## 0.3.0

### Summary

This is a major rewrite which involved completely throwing away the old code
and starting again from scratch. The rewritten module has comprehensive unit
tests (with [`rspec-puppet`](http://rspec-puppet.com)) and acceptance tests
(with [`beaker-rspec`](https://github.com/puppetlabs/beaker-rspec)).

[almanac]: https://secure.phabricator.com/book/phabricator/article/almanac/
[aphlict]: https://secure.phabricator.com/book/phabricator/article/notifications/
[phd]: https://secure.phabricator.com/book/phabricator/article/managing_daemons/
