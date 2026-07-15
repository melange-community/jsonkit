  $ dune build ./prettify.exe
Uncomment to debug
$ ocamlopt -dsource _build/default/prettify.pp.ml
  $ dune exec ./prettify.exe -- ok_parent.json
  { "extended": [ "P" ], "not_extended": [ "C", 123, "hello" ] }
  $ dune exec ./prettify.exe -- ok_child.json
  { "extended": [ "C", 123, "hello" ], "not_extended": [ "C", 123, "hello" ] }
  $ dune exec ./prettify.exe -- wrong_parent_tag.json
  Fatal error: exception Jsonkit.Of_json_error(Unexpected_variant {|expected ["P"] but got ["Wrong"]|})
  [2]
  $ dune exec ./prettify.exe -- wrong_child_tag.json
  Fatal error: exception Jsonkit.Of_json_error(Unexpected_variant {|expected ["P"] but got ["Wrong", 123, "hello"]|})
  [2]
