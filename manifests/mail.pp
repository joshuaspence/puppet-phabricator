class phabricator::mail(
  String $domain,
) {
  include sendmail

  php::extension { 'mailparse':
    provider => 'pecl',
  }

  sendmail::aliases::entry { 'phabricator':
    ensure    => 'present',
    recipient => "| ${phabricator::install_dir}/phabricator/scripts/mail/mail_handler.php",
  }

  sendmail::virtusertable::entry { 'phabricator':
    ensure => 'present',
    key    => "@${domain}",
    value  => 'phabricator@localhost',
  }
}
