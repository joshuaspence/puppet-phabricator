type Phabricator::Revision = Variant[
  Enum['master', 'stable'],
  Pattern[/^[0-9a-f]{40}$/],
]
