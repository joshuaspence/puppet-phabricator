# phabricator

[![Build Status](https://travis-ci.org/joshuaspence/puppet-phabricator.svg?branch=master)](https://travis-ci.org/joshuaspence/puppet-phabricator)
[![Puppet Forge](https://img.shields.io/puppetforge/v/joshuaspence/phabricator.svg)](https://forge.puppet.com/joshuaspence/phabricator)
[![Puppet Forge](https://img.shields.io/puppetforge/dt/joshuaspence/phabricator.svg)](https://forge.puppet.com/joshuaspence/phabricator)

## Table of Contents

1. [Description](#description)
1. [Usage](#usage)
1. [Reference](#reference)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

This module installs, configures and manages Phabricator, a suite of web-based
software development collaboration tools.

## Usage

In order to utilize this module it is necessary to configure Phabricator using
the `$config_hash` parameter. Specifically, the following settings are required:

- **`mysql.host`:** MySQL database hostname.
- **`mysql.user`:** MySQL username to use when connecting to the database.
- **`mysql.pass`:** MySQL password to use when connecting to the database.

```puppet
class { 'phabricator':
  config_hash => {
    'mysql.host' => 'localhost',
    'mysql.user' => 'user',
    'mysql.pass' => 'password',
  },

  storage_upgrade          => true,
  storage_upgrade_user     => 'admin',
  storage_upgrade_password => 'password',
}
```

## Reference

See the [documentation](https://joshuaspence.github.io/puppet-phabricator/).

## Limitations

This module has been tested on:

- Ubuntu 16.04

Testing on other platforms has been minimal and cannot be guaranteed.

## Development

Contributions to this module are welcome, but must be accompanied by
documentation, unit test coverage (with [`rspec-puppet`][rspec-puppet]) and
acceptance test coverage (with [`beaker-rspec`][beaker-rspec]). Refactoring
existing code and documentation changes do not require additional tests.

All pull requests must pass successfully through [Travis CI][travis] before
being accepted and merged. Each of the steps that is executed in
[Travis CI][travis] should be reproducible locally using the following commands:

| Task | Command |
|------|---------|
| Syntax Checks and Linting | `bundle exec rake` |
| Unit tests | `bundle exec rake spec` |
| Acceptance tests | `bundle exec rake beaker` |

[beaker-rspec]: https://github.com/puppetlabs/beaker-rspec
[rspec-puppet]: http://rspec-puppet.com/
[travis]: https://travis-ci.org/joshuaspence/puppet-phabricator/
