  $ dune build ./prettify.exe
Uncomment to debug
$ ocamlopt -dsource _build/default/prettify.pp.ml
  $ dune exec ./prettify.exe -- ok.json
  {
    "a": [ "Foo" ],
    "foo": [ [ "A" ], [ "Foo" ], [ "B", 123 ], [ "C", 234, "hello" ] ],
    "b": "where are you ?",
    "c": [ 123, 234, 345 ],
    "d": [ 123, [ 1.2, 2.3, 2.4 ], "i am here" ]
  }
  $ dune exec ./prettify.exe -- tag_as_string.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected ["A"] or ["Foo"] or ["B", _] or ["C", _, _] or ["D", { _ }] but got "A"|})
  [2]
  $ dune exec ./prettify.exe -- wrong_core_type.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected int but got string: "i am a string"|})
  [2]
  $ dune exec ./prettify.exe -- wrong_core_type_wide.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected int but got string: "i am a v ... "|})
  [2]
  $ dune exec ./prettify.exe -- deep_culprit.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected string but got object: {"a": _, "foo": _, "b": _, "c": _, "d": _}|})
  [2]
  $ dune exec ./prettify.exe -- wide_culprit.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected string but got array: [123, 234, 345, 123, 234, 345, 123, 234, ...]|})
  [2]
  $ dune exec ./prettify.exe -- missing_field.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected field "b" but got {"a": _, "foo": _, "c": _, "d": _}|})
  [2]
  $ dune exec ./prettify.exe -- unknown_tag.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected ["A"] or ["Foo"] or ["B", _] or ["C", _, _] or ["D", { _ }] but got ["Bar"]|})
  [2]
  $ dune exec ./prettify.exe -- wrong_tag_payload.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|expected ["A"] or ["Foo"] or ["B", _] or ["C", _, _] or ["D", { _ }] but got ["B", 123, "booh"]|})
  [2]
  $ dune exec ./prettify.exe -- extra_field.json
  Fatal error: exception Jsonkit.Of_json_error(Json_error {|did not expect field "bar" but got {"a": _, "foo": _, "bar": _, "b": _, "c": _, "d": _}|})
  [2]


