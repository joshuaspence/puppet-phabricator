<?php

return [
  'celerity.minify'             => false,
  'config.ignore-issues'        => [],
  'darkconsole.enabled'         => true,
  'files.enable-imagemagick'    => false,
  'load-libraries'              => [],
  'metamta.default-address'     => 'noreply@'.getenv('PHABRICATOR_DOMAIN'),
  'metamta.domain'              => getenv('PHABRICATOR_DOMAIN'),
  'mysql.host'                  => getenv('PHABRICATOR_MYSQL_HOST'),
  'mysql.pass'                  => getenv('PHABRICATOR_MYSQL_PASSWORD'),
  'mysql.user'                  => getenv('PHABRICATOR_MYSQL_USER'),
  'phabricator.base-uri'        => 'http://'.getenv('PHABRICATOR_DOMAIN'),
  'phabricator.developer-mode'  => true,
  'phabricator.show-prototypes' => true,
  'phabricator.timezone'        => 'Etc/UTC',
  'pygments.enabled'            => false,
];
