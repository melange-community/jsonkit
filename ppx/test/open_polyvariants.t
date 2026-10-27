Polymorphic variant rows that are not closed — `[> ... ]`, `[< ... ]` and
`[< ... > ... ]` — are rejected on both backends, both as the whole type
declaration and nested inside another type. The forward compatibility they
were asked for is covered by a closed row with a [@json.catch_all] or
[@json.allow_any] row.

  $ echo 'type t = [> `A ] [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 9-16:
  1 | type t = [> `A ] [@@deriving json]
               ^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = [< `A | `B ] [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 9-21:
  1 | type t = [< `A | `B ] [@@deriving json]
               ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = [< `A > `A ] [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 9-21:
  1 | type t = [< `A > `A ] [@@deriving json]
               ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = { a : [> `A ] } [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 15-22:
  1 | type t = { a : [> `A ] } [@@deriving json]
                     ^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = { a : [< `A | `B ] } [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 15-27:
  1 | type t = { a : [< `A | `B ] } [@@deriving json]
                     ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = { a : [< `A > `A ] } [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -impl -
  File "-", line 1, characters 15-27:
  1 | type t = { a : [< `A > `A ] } [@@deriving json]
                     ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = [> `A ] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 9-16:
  1 | type t = [> `A ] [@@deriving json]
               ^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = [< `A | `B ] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 9-21:
  1 | type t = [< `A | `B ] [@@deriving json]
               ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = [< `A > `A ] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 9-21:
  1 | type t = [< `A > `A ] [@@deriving json]
               ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = { a : [> `A ] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 15-22:
  1 | type t = { a : [> `A ] } [@@deriving json]
                     ^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = { a : [< `A | `B ] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 15-27:
  1 | type t = { a : [< `A | `B ] } [@@deriving json]
                     ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

  $ echo 'type t = { a : [< `A > `A ] } [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 15-27:
  1 | type t = { a : [< `A > `A ] } [@@deriving json]
                     ^^^^^^^^^^^^
  Error: non closed polyvariants ([> ...] and [< ...]) are not supported; for forward compatibility use a closed polyvariant with a [@json.catch_all] or [@json.allow_any] row
  [1]

The closed form the error points at keeps working.

  $ echo 'type t = [ `A | `Unknown of Jsonkit.unknown_variant_case [@json.catch_all] ] [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -impl - > /dev/null

  $ echo 'type t = [ `A | `Unknown of Jsonkit.unknown_variant_case [@json.catch_all] ] [@@deriving json]' | ../browser/ppx_deriving_json_js_test.exe -impl - > /dev/null
