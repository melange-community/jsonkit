The schema of a type without parameters is a function of unit.
A schema that the program never calls costs nothing at module load, so a bundler can drop it.

  $ cat > shapes.ml <<'EOF'
  > type point = { x : int; y : int } [@@deriving json, jsonschema]
  > type ('a, 'b) pair = { first : 'a; second : 'b } [@@deriving jsonschema]
  > type segment = (point, point) pair [@@deriving jsonschema]
  > type tree = Leaf | Node of tree * point list [@@deriving jsonschema]
  > EOF

  $ cat > shapes.mli <<'EOF'
  > type point = { x : int; y : int } [@@deriving json, jsonschema]
  > type ('a, 'b) pair = { first : 'a; second : 'b } [@@deriving jsonschema]
  > type segment = (point, point) pair [@@deriving jsonschema]
  > type tree = Leaf | Node of tree * point list [@@deriving jsonschema]
  > EOF

  $ cat > main.ml <<'EOF'
  > let () = Js.log (Jsonkit.Json.to_string (Shapes.point_to_json { x = 1; y = 2 }))
  > let () =
  >   Js.log
  >     (Js.Json.stringify
  >        (Jsonkit.Jsonschema.declassify (Shapes.segment_jsonschema ())))
  > EOF

  $ cat > dune-project <<'EOF'
  > (lang dune 3.11)
  > (using melange 0.1)
  > EOF

  $ cat > dune <<'EOF'
  > (library
  >  (name shapes_lib)
  >  (modes melange)
  >  (modules shapes main)
  >  (libraries jsonkit-melange)
  >  (flags :standard -open Jsonkit.Primitives)
  >  (preprocess (pps melange.ppx jsonkit-melange.ppx)))
  > (melange.emit
  >  (alias js)
  >  (target output)
  >  (modules)
  >  (libraries shapes_lib)
  >  (module_systems commonjs))
  > EOF

  $ dune build @js

  $ grep -E '^(const|let|function) [a-z_]+_jsonschema' _build/default/output/shapes.js
  function point_jsonschema(param) {
  function pair_jsonschema(jsonschema__a, jsonschema__b) {
  function segment_jsonschema(param) {
  function tree_jsonschema(param) {

  $ node _build/default/output/main.js
  {"x":1,"y":2}
  {"type":"object","properties":{"second":{"type":"object","properties":{"y":{"type":"integer"},"x":{"type":"integer"}},"required":["y","x"],"additionalProperties":true},"first":{"type":"object","properties":{"y":{"type":"integer"},"x":{"type":"integer"}},"required":["y","x"],"additionalProperties":true}},"required":["second","first"],"additionalProperties":true}
