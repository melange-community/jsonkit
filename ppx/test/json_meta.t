[@@deriving json_meta] lists a record's JSON keys, with [@json.key] applied.

  $ echo 'type user = { id : int; name : string [@json.key "full_name"] } [@@deriving json_meta]' | ../native/ppx_deriving_json_native_test.exe -impl -
  type user = {
    id: int ;
    name: string [@json.key "full_name"]}[@@deriving json_meta]
  include
    struct
      let _ = fun (_ : user) -> ()
      let user_json_keys = (["id"; "full_name"] : string list)
      let _ = user_json_keys
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

A type named t drops the prefix, like the converters do.

  $ echo 'type t = { a : int } [@@deriving json_meta]' | ../native/ppx_deriving_json_native_test.exe -impl -
  type t = {
    a: int }[@@deriving json_meta]
  include
    struct
      let _ = fun (_ : t) -> ()
      let json_keys = (["a"] : string list)
      let _ = json_keys
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Type parameters do not reach the keys, so the value takes no arguments.

  $ echo 'type '"'"'a box = { v : '"'"'a; tag : string } [@@deriving json_meta]' | ../native/ppx_deriving_json_native_test.exe -impl -
  type 'a box = {
    v: 'a ;
    tag: string }[@@deriving json_meta]
  include
    struct
      let _ = fun (_ : 'a box) -> ()
      let box_json_keys = (["v"; "tag"] : string list)
      let _ = box_json_keys
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Every declaration of a group gets its own value.

  $ echo 'type a = { x : int } and b = { y : int } [@@deriving json_meta]' | ../native/ppx_deriving_json_native_test.exe -impl -
  type a = {
    x: int }
  and b = {
    y: int }[@@deriving json_meta]
  include
    struct
      let _ = fun (_ : a) -> ()
      let _ = fun (_ : b) -> ()
      let a_json_keys = (["x"] : string list)
      and b_json_keys = (["y"] : string list)
      let _ = a_json_keys
      and _ = b_json_keys
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Signatures carry the value too.

  $ echo 'type user = { id : int } [@@deriving json_meta]' | ../native/ppx_deriving_json_native_test.exe -intf -
  type user = {
    id: int }[@@deriving json_meta]
  include sig [@@@ocaml.warning "-32"] val user_json_keys : string list end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

It derives alongside the converters.

  $ echo 'type user = { id : int } [@@deriving json, json_meta]' | ../native/ppx_deriving_json_native_test.exe -impl - | grep json_keys
      let user_json_keys = (["id"] : string list)
      let _ = user_json_keys

The Melange deriver emits the same value: no JSON runtime is involved.

  $ echo 'type user = { id : int; name : string [@json.key "full_name"] } [@@deriving json_meta]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  type user = {
    id: int ;
    name: string [@json.key "full_name"]}[@@deriving json_meta]
  include
    struct
      let _ = fun (_ : user) -> ()
      let user_json_keys = (["id"; "full_name"] : string list)
      let _ = user_json_keys
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Anything that is not a record is rejected where it is written.

  $ echo 'type c = A | B [@@deriving json_meta]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 0-37:
  1 | type c = A | B [@@deriving json_meta]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@@deriving json_meta] expects a record type
  [1]

  $ echo 'type u = int [@@deriving json_meta]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 0-35:
  1 | type u = int [@@deriving json_meta]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@@deriving json_meta] expects a record type
  [1]
