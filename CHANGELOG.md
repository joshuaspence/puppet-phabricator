# Changelog

## 0.3.2

### Features

- Added support for managing [Aphlict][aphlict].

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

[aphlict]: https://secure.phabricator.com/book/phabricator/article/notifications/
[phd]: https://secure.phabricator.com/book/phabricator/article/managing_daemons/
