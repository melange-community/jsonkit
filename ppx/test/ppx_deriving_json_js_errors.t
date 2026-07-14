

  $ echo 'type t = { a: int option; [@drop_default] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 11-41:
  1 | type t = { a: int option; [@drop_default] } [@@deriving json]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@drop_default] requires either [@option] or [@default]
  [1]

  $ echo 'type t = { a: int option; [@option] [@default Some 0] [@drop_default] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 11-69:
  1 | type t = { a: int option; [@option] [@default Some 0] [@drop_default] } [@@deriving json]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@drop_default] cannot be used with both [@option] and [@default]
  [1]

  $ echo 'type t = { a: int; [@drop_default (=)] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 11-38:
  1 | type t = { a: int; [@drop_default (=)] } [@@deriving json]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@drop_default expr] requires [@default]
  [1]

  $ echo 'type t = { a: int option; [@option] [@drop_default (=)] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 11-55:
  1 | type t = { a: int option; [@option] [@drop_default (=)] } [@@deriving json]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@drop_default expr] cannot be used with [@option]
  [1]

  $ echo 'type t = { a: int option; [@option] [@drop_default] [@drop_default_if_json_equal] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 11-81:
  1 | type t = { a: int option; [@option] [@drop_default] [@drop_default_if_json_equal] } [@@deriving json]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@drop_default] and [@drop_default_if_json_equal] are mutually exclusive
  [1]

  $ echo 'type t = { a: int option; [@option] [@default Some 0] [@drop_default_if_json_equal] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 11-83:
  1 | type t = { a: int option; [@option] [@default Some 0] [@drop_default_if_json_equal] } [@@deriving json]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@drop_default_if_json_equal] cannot be used with both [@option] and [@default]. Use [@json.default] only.
  [1]

  $ echo 'type t = { a: int option; [@option] [@drop_default_if_json_equal] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 11-65:
  1 | type t = { a: int option; [@option] [@drop_default_if_json_equal] } [@@deriving json]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@drop_default_if_json_equal] cannot be used with [@option]. Use [@drop_default] instead.
  [1]

  $ echo 'type t = { a: int } [@@deriving json] [@@json.allow_extra_fields] [@@json.disallow_extra_fields]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 0-96:
  1 | type t = { a: int } [@@deriving json] [@@json.allow_extra_fields] [@@json.disallow_extra_fields]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@json.allow_extra_fields] and [@json.disallow_extra_fields] are mutually exclusive
  [1]

  $ echo 'type t = A of { a: int } [@json.allow_extra_fields] [@json.disallow_extra_fields] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 9-81:
  1 | type t = A of { a: int } [@json.allow_extra_fields] [@json.disallow_extra_fields] [@@deriving json]
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@json.allow_extra_fields] and [@json.disallow_extra_fields] are mutually exclusive
  [1]

[@json.catch_all] needs somewhere to put the unknown tag and its payload: a
single argument, or an inline record with exactly the fields `tag` and
`payload`.

  $ echo 'type t = A [@json.catch_all] | B [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 9-10:
  1 | type t = A [@json.catch_all] | B [@@deriving json]
               ^
  Error: [@json.catch_all] requires exactly one argument: a record type with fields `tag : string` and `payload : Jsonkit.t list option` (typically [Jsonkit.unknown_variant_case])
  [1]

  $ echo 'type t = A of int * int [@json.catch_all] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 9-10:
  1 | type t = A of int * int [@json.catch_all] [@@deriving json]
               ^
  Error: [@json.catch_all] requires exactly one argument: a record type with fields `tag : string` and `payload : Jsonkit.t list option` (typically [Jsonkit.unknown_variant_case])
  [1]

  $ echo 'type t = A of { tag: string } [@json.catch_all] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 0-65:
  1 | type t = A of { tag: string } [@json.catch_all] [@@deriving json]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@json.catch_all] inline record must have exactly two fields named `tag` and `payload` (in that order), with types `string` and `Jsonkit.t list option`
  [1]

  $ echo 'type t = A of { payload: Jsonkit.t list option; tag: string } [@json.catch_all] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 0-97:
  1 | type t = A of { payload: Jsonkit.t list option; tag: string } [@json.catch_all] [@@deriving json]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@json.catch_all] inline record must have exactly two fields named `tag` and `payload` (in that order), with types `string` and `Jsonkit.t list option`
  [1]

The [@drop_default] family only constrains encoding, so an of_json-only
derivation accepts combinations that [@@deriving json] rejects (see the
[@drop_default expr] requires [@default] case above).

  $ echo 'type t = { a: int; [@drop_default (=)] } [@@deriving of_json]' | ../browser/ppx_deriving_json_js_test.exe -impl - > /dev/null
