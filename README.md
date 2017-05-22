# phabricator

[![Build Status](https://travis-ci.org/joshuaspence/puppet-phabricator.svg?branch=master)](https://travis-ci.org/joshuaspence/puppet-phabricator)

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

For developing this module, `bundle exec rake` should be all is required.
