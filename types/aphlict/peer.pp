type Phabricator::Aphlict::Peer = Struct[
  {
    'host' => String,
    'port' => Integer,
    'protocol' => Enum['http', 'https'],
  }
]
