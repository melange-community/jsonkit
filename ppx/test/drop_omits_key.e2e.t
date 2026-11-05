On Melange a dropped field is absent from the emitted object, not present
with the value `undefined`, so `Object.keys` does not see it. This is only
observable through the object itself: `JSON.stringify` skips `undefined`
values and so hides the difference.

  $ echo '(lang dune 3.11)
  > (using melange 0.1)' > dune-project

  $ echo '
  > (library
  >  (name lib)
  >  (modes melange)
  >  (modules main)
  >  (libraries jsonkit-melange)
  >  (flags :standard -w -20-37-69 -open Jsonkit.Primitives)
  >  (preprocess (pps melange.ppx jsonkit-melange.ppx)))
  > (melange.emit
  >  (alias js)
  >  (target output)
  >  (modules)
  >  (libraries lib)
  >  (module_systems commonjs))' > dune

  $ cat > main.ml <<"EOF"
  > let equal_int = Int.equal
  > type t = {
  >   a : int;
  >   b_opt : int option; [@option] [@json.drop_default]
  >   c : int; [@json.default 0] [@json.drop_default]
  >   d : int; [@json.default 0] [@json.drop_default Int.equal]
  >   e : int; [@json.default 0] [@json.drop_default_if_json_equal]
  >   z : int;
  > } [@@deriving to_json]
  > let keys t = Js.Dict.keys (Obj.magic (to_json t) : Js.Json.t Js.Dict.t)
  > let all_dropped = { a = 1; b_opt = None; c = 0; d = 0; e = 0; z = 9 }
  > let none_dropped = { a = 1; b_opt = Some 2; c = 3; d = 4; e = 5; z = 9 }
  > let () = Js.log (keys all_dropped)
  > let () = Js.log (keys none_dropped)
  > let () = Js.log (Js.Json.stringify (to_json all_dropped))
  > EOF

  $ dune build @js

  $ node ./_build/default/output/main.js
  [ 'a', 'z' ]
  [ 'a', 'b_opt', 'c', 'd', 'e', 'z' ]
  {"a":1,"z":9}
