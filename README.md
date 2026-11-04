# jsonkit

jsonkit turns JSON into typed OCaml values and back, with a `[@@deriving json]`
PPX that writes the converters for you. It ships as two packages, one per
compilation target:

- `jsonkit` for native OCaml, where a JSON value is a `Yojson.Basic.t`;
- `jsonkit-melange` for [Melange](https://melange.re/), where a JSON value is
  the `Js.Json.t` that `JSON.parse` hands back, with no dependency beyond
  Melange itself.

Both packages expose the same `Jsonkit` module, accept the same attributes and
produce the same wire format, so a type shared between a native server and a
Melange client derives its converters from one source, with no conditional
compilation.

Based on [@glennsl/bs-json](https://github.com/glennsl/bs-json) and former
melange-json.

## Inspecting a JSON value portably

Code that has to look inside a JSON value and compile on native and on Melange
should use `Jsonkit.classify` instead of matching on Yojson constructors or
reaching for `Js.Json`:

```ocaml
val classify :
  Jsonkit.t ->
  [ `Null | `String of string | `Float of float | `Int of int
  | `Bool of bool | `List of Jsonkit.t list
  | `Assoc of (string * Jsonkit.t) list ]
```

`Jsonkit.declassify` is its inverse. On native both are the identity function;
on Melange they test the JavaScript value and wrap, or unwrap, one level of it.

## Installation

Install the [opam](https://opam.ocaml.org/) package manager, then the package
for your target.

### Native OCaml

```sh
opam install jsonkit
```

```dune
(library
 (name my_lib)
 (libraries jsonkit)
 (preprocess
  (pps jsonkit.ppx)))
```

### Melange

```sh
opam install jsonkit-melange
```

```dune
(library
 (name my_lib)
 (modes melange)
 (libraries jsonkit-melange)
 (preprocess
  (pps jsonkit-melange.ppx)))
```

Each package contains both the runtime library and its [ppx deriver
plugin](https://ocaml.org/docs/metaprogramming#attributes-and-derivers); there
is nothing else to install.

## Deriving JSON converters

Everything in this section works the same on native and on Melange.

To generate JSON converters for a type, add the `[@@deriving json]` attribute
to the type declaration, ensuring the converters for primitives like `int` and
`string` are in scope if necessary:

```ocaml
open Jsonkit.Primitives

type t = {
  a: int;
  b: string;
} [@@deriving json]
```

This will generate the following pair of functions:

```ocaml
val of_json : Jsonkit.t -> t
val to_json : t -> Jsonkit.t
```

`Jsonkit.t` is `Yojson.Basic.t` under `jsonkit` and `Js.Json.t` under
`jsonkit-melange`, and the generated signatures name that type directly. A type
called something other than `t` gets `<name>_of_json` and `<name>_to_json`, and
`[@@deriving of_json]` or `[@@deriving to_json]` generates a single direction.

### Primitives semantics

The following table summarizes the correspondence between OCaml types and JSON values for the primitives:

| OCaml type        | JSON value | Sample JSON value                                                   |
| ----------------- | ---------- | ------------------------------------------------------------------- |
| `int`, `float`    | Number     | `1.23`                                                              |
| `int64`           | String     | `"1234567890"`                                                      |
| `bool`            | Boolean    | `true`                                                              |
| `string`          | String     | `"foo"`                                                             |
| `list`, `array`   | Array      | `[1, 2, 3]`                                                         |
| `'a option`       | Null or 'a | `string option` is `null` or `"foo"`; `int` option is `null` or `1` |
| `unit`            | Null       | `null`                                                              |
| `('a, 'b) result` | Array      | `(int, string) result` is `["Ok", 1]` or `["Error", "error"]`       |

### Generating JSON converters from type expressions

You can also generate JSON converters for a type expression using the `to_json`
and `of_json` extension points:

```ocaml
let json = [%to_json: int * string] (42, "foo")
```

Labeled tuples (OCaml 5.4+) are supported as well, and serialize to JSON objects
keyed by each label:

```ocaml
let json = [%to_json: x:int * y:int] (~x:1, ~y:2)
(* {"x": 1, "y": 2} *)

let (~x, ~y) =
  [%of_json: x:int * y:int] (Jsonkit.of_string {|{"x": 1, "y": 2}|})
(* x = 1, y = 2 *)
```

Members without a label are keyed by their position:

```ocaml
let json = [%to_json: x:int * string] (~x:1, "foo")
(* {"x": 1, "1": "foo"} *)
```

### `[@json.default E]`: default values for records

```ocaml
type t = {
  a: int;
  b: string [@json.default "-"];
} [@@deriving of_json]

let t = of_json (Jsonkit.of_string {|{"a": 42}|})
(* t = { a = 42; b = "-"; } *)
```

### Extra fields on records

By default, JSON object keys that are not part of the OCaml record type are
ignored.

```ocaml
type t = {
  a: int;
} [@@deriving json]

let t = of_json (Jsonkit.of_string {|{"a": 42, "extra": "ignore me"}|})
(* t = { a = 42 } *)
```

`[@json.allow_extra_fields]` is still accepted for backwards compatibility, but
is no longer necessary.

Use `[@json.disallow_extra_fields]` to reject unknown keys instead:

```ocaml
type strict = {
  a: int;
} [@@deriving json] [@@json.disallow_extra_fields]

let _ = strict_of_json (Jsonkit.of_string {|{"a": 42, "extra": "fail"}|})
(* raises: did not expect field "extra" *)
```

It works the same on an inline record in a variant constructor, written there
as a single-`@` attribute: `| A of { a: int } [@json.disallow_extra_fields]`.

### `[@json.option]`: a shortcut for `[@json.default None]`

On a field of type `_ option`, the default is `None`:

```ocaml
type t = {
  a: int;
  b: string option [@json.option];
} [@@deriving of_json]

let t = of_json (Jsonkit.of_string {|{"a": 42}|})
(* t = { a = 42; b = None; } *)
```

### `[@json.drop_default]`: drop default values from JSON

On a field that already has `[@json.option]` or `[@json.default]`, this makes
`to_json` leave the field out when its value matches the default.

In its flag form, with no argument, it checks for `None` alongside
`[@json.option]`, and needs an `equal_<type>` in scope alongside
`[@json.default]`:

```ocaml
let equal_string = String.equal

type t = {
  a: int;
  b: string option [@json.option] [@json.drop_default];
  c: string [@json.default "-"] [@json.drop_default];
} [@@deriving to_json]

let t = to_json { a = 1; b = None; c = "-"; }
(* {"a": 1} *)
```

For parameterized types the inner type's equality is passed as an argument, so
a field of type `int list` calls `equal_list equal_int`, and `int list list`
calls `equal_list (equal_list equal_int)`. Both have to be in scope.

You can also provide a custom comparison function of type `'a -> 'a -> bool` directly:

```ocaml
type t = {
  f: float [@json.default 0.0] [@json.drop_default Float.equal];
} [@@deriving to_json]

let json = to_json { f = 0.0 }
(* {} *)
```

### `[@json.drop_default_if_json_equal]`: drop defaults by comparing JSON output

A (mutually exclusive) alternative to `[@json.drop_default]` that compares values at the JSON level
rather than requiring an `equal_<type>` function. This is useful for complex or
nested types where you already have `to_json` but don't want to derive or write
equality functions:

```ocaml
type color = { r: int; g: int; b: int } [@@deriving json]

type style = {
  font_size: int;
  background: color
    [@json.default { r = 255; g = 255; b = 255 }]
    [@json.drop_default_if_json_equal];
} [@@deriving json]

let json = to_json { font_size = 12; background = { r = 255; g = 255; b = 255 } }
(* {"font_size": 12} *)
```

### `[@json.key "S"]`: customizing keys for record fields

```ocaml
type t = {
  a: int [@json.key "A"];
  b: string [@json.key "B"];
} [@@deriving of_json]

let t = of_json (Jsonkit.of_string {|{"A": 42, "B": "foo"}|})
(* t = { a = 42; b = "foo"; } *)
```

### `[@json.name "S"]`: customizing the representation of a variant case

```ocaml
type t = A | B [@json.name "bbb"] [@@deriving json]

let json = to_json B
(* "bbb" *)
```

### `[@@json.compact_variants]`: compact encoding for variants and polyvariants

The `[@@json.compact_variants]` attribute changes the JSON encoding of variant
and polyvariant types to a compact form:

- Constructors **without arguments** are encoded as plain JSON strings.
- Constructors **with arguments** are encoded as JSON arrays
  `["ConstructorName", arg1, ...]`.

```ocaml
type t = A | B of int | C of int * string [@@deriving json] [@@json.compact_variants]

let json_a = to_json A
(* "A" *)

let json_b = to_json (B 42)
(* ["B", 42] *)

let json_c = to_json (C (1, "x"))
(* ["C", 1, "x"] *)
```

This also works for polyvariant types:

```ocaml
type t = [`A | `B of int] [@@deriving json] [@@json.compact_variants]
```

### `[@json.catch_all]`: catch-all constructor for unknown string tags

The `[@json.catch_all]` attribute marks a constructor as the catch-all for any
unrecognised string tag. The constructor's argument is the library type
`Jsonkit.unknown_variant_case`, a record with fields `tag : string` and
`payload : Jsonkit.t list option`. The decoder routes bare unknown
strings *and* unknown array variants — including their payload — into this
constructor; the encoder re-emits the exact wire shape, so decoding/encoding
round-trips.

Pairs naturally with `[@@json.compact_variants]` so the known cases are also
bare strings.

```ocaml
type evt =
  | Login [@json.name "login"]
  | Click of int [@json.name "click"]
  | Unknown of Jsonkit.unknown_variant_case [@json.catch_all]
[@@deriving json] [@@json.compact_variants]
```

The same syntax works for polymorphic variants:

```ocaml
type evt = [
  | `Login [@json.name "login"]
  | `Click of int [@json.name "click"]
  | `Unknown of Jsonkit.unknown_variant_case [@json.catch_all]
] [@@deriving json] [@@json.compact_variants]
```

#### Wire shape mapping

`payload` distinguishes the wire shape so the value round-trips faithfully:

| Wire JSON               | Decoded                                                   | Re-encodes as          |
|-------------------------|-----------------------------------------------------------|------------------------|
| `"future_tag"`          | `{ tag = "future_tag"; payload = None }`                  | `"future_tag"`         |
| `["future_tag"]`        | `{ tag = "future_tag"; payload = Some [] }`               | `["future_tag"]`       |
| `["future_tag", 42]`    | `{ tag = "future_tag"; payload = Some [`Int 42] }`        | `["future_tag", 42]`   |

#### Decoding order with inherited polymorphic variants

When a polymorphic variant inherits other types (`[ base | `Own | ... ]`), the
decoder always tries, in this order, whatever the row order in the definition:

1. the type's own tags, in definition order
2. the inherited types, in definition order
3. the type's own `[@json.catch_all]` row
4. an error, or the `[@json.allow_any]` constructor if there is one

So a catch-all never shadows a tag an inherited type knows:

```ocaml
type known = [ `Alpha | `Beta ] [@@deriving json]
type evt = [ known | `Unknown of Jsonkit.unknown_variant_case [@json.catch_all] ]
[@@deriving json]

(* ["Alpha"] decodes to `Alpha, ["Zzz"] to `Unknown { tag = "Zzz"; ... } *)
```

Note that a catch-all *inside* an inherited type accepts every tag it is
offered, so it hides the inherited types listed after it and the outer
catch-all. Put the catch-all on the outermost type when you can.

### `[@@deriving json_string]`: a shortcut for JSON string conversion

For convenience, one can use `[@@deriving json_string]` to generate converters
directly to and from JSON strings:

```ocaml
type t = A [@@deriving json, json_string]

let "\"A\"" = to_json_string A
let A = of_json_string "\"A\""
```

Similarly, there's `[@@deriving to_json_string]` and `[@@deriving
of_json_string]` to generate the converters separately.

## Melange runtime API

The combinators below exist only in `jsonkit-melange`. The native package
provides `Jsonkit.Of_json` and `Jsonkit.To_json` too, but only with the
primitives the deriver needs; code written against `field`, `one_of` and
friends does not compile on native.

A decoder takes a `Js.Json.t` and returns a value, or raises `Of_json_error`.
Others take a decoder and return one, so they compose:
`Jsonkit.Of_json.(array int)` decodes an `int array`.

### Example

```reason
type line = {
  start: point,
  end_: point,
  thickness: option(int)
}
and point = {
  x: int,
  y: int
};

module Decode = {
  let point = json =>
    Jsonkit.Of_json.{
      x: json |> field("x", int),
      y: json |> field("y", int)
    };

  let line = json =>
    Jsonkit.Of_json.{
      start:     json |> field("start", point),
      end_:      json |> field("end", point),
      thickness: json |> try_or_none(field("thickness", int))
    };
};

let data = {| {
  "start": { "x": 1, "y": -4 },
  "end":   { "x": 5, "y": 8 }
} |};

let line = data |> Jsonkit.of_string
                |> Decode.line;
```

`Jsonkit.Of_json.{ ... }` builds an ordinary record with the module opened
inside the braces, which is why `field` and `int` need no prefix there.

See [examples](./examples/) for more, and
[`jsonkit_json.mli`](./src/jsonkit_json.mli) for the full API.

### Writing custom decoders and encoders

`'a of_json` is an alias for `Js.Json.t -> 'a`, so `Decode.point` above is
already a `point of_json` and composes like any built-in one:
`Of_json.array Decode.point` decodes a `point array`.

A decoder that takes another decoder as an argument is written the same way,
with the argument used where a fixed decoder would otherwise be:

```reason
let point = (decodeNumber, json) =>
  Jsonkit.Of_json.{
    x: json |> field("x", decodeNumber),
    y: json |> field("y", decodeNumber)
  };

let intPoint = point(Jsonkit.Of_json.int);
```

Encoders are the mirror image: `'a to_json` is an alias for `'a -> Js.Json.t`.

## JSON Schema (`[@@deriving jsonschema]`)

The PPX can generate a [JSON Schema](https://json-schema.org/) from a type with
`[@@deriving jsonschema]`. The schema matches the output produced by the
json derivers.

```ocaml
open Jsonkit.Primitives

type t = {
  name: string;
  age: int;
} [@@deriving jsonschema]

let schema = Jsonkit.Jsonschema.make t_jsonschema
```

See **[JSONSCHEMA.md](./JSONSCHEMA.md)** for the full documentation: setup,
conversion rules, and all supported annotations.

## License

This work is dual-licensed under LGPL 3.0 and MPL 2.0. You can choose between
one of them if you use this work.

Please see LICENSE.LGPL-3.0 and LICENSE.MPL-2.0 for the full text of each
license.

`SPDX-License-Identifier: LGPL-3.0 OR MPL-2.0`
