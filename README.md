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

This module installs, configures and manages [Phabricator][phabricator], a
suite of web-based software development collaboration tools, including:

- [Arcanist](https://www.phacility.com/phabricator/arcanist/)
- [Differential](https://www.phacility.com/phabricator/differential/)
- [Diffusion](https://www.phacility.com/phabricator/diffusion/)
- [Maniphest](https://www.phacility.com/phabricator/maniphest/)
- [Phriction](https://www.phacility.com/phabricator/phriction/)

Phabricator is offered as a [hosted service](https://www.phacility.com/pricing/)
by [Phacility](phacility), but can also be installed
[on-premise][installation-guide].

## Usage

In order to utilize this module it is necessary to configure Phabricator using
the `$config_hash` parameter. Specifically, the following settings are required:

- **`mysql.host`:** MySQL database hostname.
- **`mysql.user`:** MySQL username to use when connecting to the database.
- **`mysql.pass`:** MySQL password to use when connecting to the database.

There are many other settings that can be passed to the `$config_hash`
parameter, but the above settings should be the minimal configuration that is
required in order for Phabricator to be functional. The `$config_hash`
parameter is JSON-encoded and written to `conf/local/local.json`. See
[Advanced Configuration](advanced-configuration) for further information on
configuring Phabricator.

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

include phabricator::aphlict
include phabricator::daemons
```

### Storage Upgrades and Adjustments
Phabricator uses MySQL or another MySQL-compatible database (such as MariaDB or
Amazon RDS). Phabricator consists of a `./bin/storage` script which can be used
to manage the database schema and apply storage upgrades and adjustments. You
can find more information about these processes in the official documentation
(see [Storage: Configuring MySQL](storage-upgrades) and [Managing Storage Adjustments](storage-adjustments)).

This module can, optionally, execute `./bin/storage upgrade` automatically in
order to apply storage upgrades and adjustments. Whilst I haven't observed any
issues using Puppet to apply storage upgrades and adjustments, I suspect that
many (most?) users of this module would prefer to apply storage upgrades and
adjustments using some other mechanism, perhaps as a step in a shell script
used for deployments. As such, `$storage_upgrade` defaults to `false`.

Users of this module that choose to set `$storage_upgrade` to `true` should be
aware of the following caveats:

- Storage upgrades can take a long time to complete. Generally the time taken
  to apply storage upgrades will be proportional to the amount of data stored
  in Phabricator. Whilst storage upgrades should be able to be applied multiple
  times without adverse side effects, terminating the `./bin/storage upgrade`
  workflow is strongly advised against.
- It is strongly recommended that a Phabricator installation is taken offline
  before storage upgrades are applied.

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

[advanced-configuration]: https://secure.phabricator.com/book/phabricator/article/advanced_configuration/
[beaker-rspec]: https://github.com/puppetlabs/beaker-rspec
[installation-guide]: https://secure.phabricator.com/book/phabricator/article/installation_guide/
[phabricator]: https://www.phacility.com/phabricator/
[phacility]: https://www.phacility.com/
[rspec-puppet]: http://rspec-puppet.com/
[storage-adjustments]: https://secure.phabricator.com/book/phabricator/article/storage_adjust/
[storage-upgrades]: https://secure.phabricator.com/book/phabricator/article/configuration_guide/
[travis]: https://travis-ci.org/joshuaspence/puppet-phabricator/
