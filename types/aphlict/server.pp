type Phabricator::Aphlict::Server = Struct[
  {
    'listen' => Optional[String],
    'port' => Integer,
    'ssl.cert' => Optional[Stdlib::Unixpath],
    'ssl.chain' => Optional[Stdlib::Unixpath],
    'ssl.key' => Optional[Stdlib::Unixpath],
    'type' => Enum['admin', 'client'],
  }
]
