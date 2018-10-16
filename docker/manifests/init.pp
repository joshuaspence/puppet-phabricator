include apt
include dummy_service
include phabricator
include php

# Ensure that `apt-get update` is executed before any packages are
# installed. See https://github.com/puppetlabs/puppetlabs-apt/#adding-new-sources-or-ppas.
Class['apt::update'] -> Package <| title != 'apt-transport-https' and title != 'ca-certificates' and title != 'software-properties-common' |>
