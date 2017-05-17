# phabricator

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

* Ubuntu 16.04

Testing on other platforms has been minimal and cannot be guaranteed.

## Development

For developing this module, `bundle exec rake` should be all is required.
