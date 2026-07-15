Wire test: JSON produced by jsonkit's [to_json] encoder must validate
against the schema produced by the [jsonschema] deriver for the same type.
Requires the [check-jsonschema] CLI on PATH.

  $ ./wire.exe
  simple_record: 2/2 valid
  defaults_record: 2/2 valid
  keyed_record: 1/1 valid
  kind: 3/3 valid
  payload_variant: 4/4 valid
  compact_variant: 3/3 valid
  poly_variant: 2/2 valid
  pair: 1/1 valid
  nested: 1/1 valid
  tree: 2/2 valid
  containers: 1/1 valid
  primitives: 1/1 valid
  outcome: 2/2 valid
  optionals: 2/2 valid
  matrix: 1/1 valid
  labeled: 1/1 valid
  roster: 1/1 valid
  player_scores: 1/1 valid
  contact: 1/1 valid
  foo: 2/2 valid
  recursive_tuple: 2/2 valid
  poly_payload: 3/3 valid
  poly_inherit: 4/4 valid
  either: 2/2 valid
  link: 2/2 valid
  bounded: 3/3 valid
  timestamped: 1/1 valid
  annotated: 2/2 valid
  named_variant: 2/2 valid
  named_poly: 2/2 valid
  key_opt: 2/2 valid
