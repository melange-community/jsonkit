# jsonkit

Compositional JSON encode/decode library and PPX for
[Melange](https://melange.re/).

Based on [@glennsl/bs-json](https://github.com/glennsl/bs-json) and former melange-json.

The Decode module in particular provides a basic set of decoder functions to be
composed into more complex decoders. A decoder is a function that takes a
`Js.Json.t` and either returns a value of the desired type if successful or
raises an `Of_json_error` exception if not. Other functions accept a decoder and
produce another decoder. Like `array`, which when given a decoder for type `t`
will return a decoder that tries to produce a value of type `t array`. So to
decode an `int array` you combine `Jsonkit.Of_json.int` with `Jsonkit.Of_json.array`
into `Jsonkit.Of_json.(array int)`. An array of arrays of ints? `Jsonkit.Of_json.(array
(array int))`. Dict containing arrays of ints? `Jsonkit.Of_json.(dict (array int))`.

## Example

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

NOTE: `Jsonkit.Of_json.{ ... }` creates an ordinary record, but also opens the
`Jsonkit.Of_json` module locally, within the scope delimited by the curly braces, so
we don't have to qualify the functions we use from it, like `field`, `int` and
`try_or_none` here. You can also use `Jsonkit.Of_json.( ... )` to open the module
locally within the parentheses, if you're not creating a record.

See [examples](./examples/) for more.

## Installation

Install [opam](https://opam.ocaml.org/) package manager.

Then:

```sh
opam install jsonkit-melange
```

# Setup

Add `jsonkit-melange` to the `libraries` field in your `dune` file:

```lisp
; ...
  (libraries jsonkit-melange)
; ...
```

## Documentation

### API

For the moment, please see the interface files:

* [Jsonkit](./src/jsonkit.mli)

### Writing custom decoders and encoders

If you look at the type signature of `Jsonkit.Decode.array`, for example, you'll
see it takes an `'a decoder` and returns an `'a array decoder`. `'a decoder` is
just an alias for `Js.Json.t -> 'a`, so if we expand the type signature of
`array` we'll get `(Js.Json.t -> 'a) -> Js.Json.t -> 'a array`. We can now see
that it is a function that takes a decoder and returns a function, itself a
decoder. Applying the `int` decoder to `array` will give us an `int array
decoder`, a function `Js.Json.t -> int array`.

If you've written a function that takes just `Js.Json.t` and returns
user-defined types of your own, you've already been writing composable decoders!
Let's look at `Decode.point` from the example above:

```reason
let point = json => {
  open! Jsonkit.Decode;
  {
    x: json |> field("x", int),
    y: json |> field("y", int)
  };
};
```

This is a function `Js.Json.t -> point`, or a `point decoder`. So if we'd like
to decode an array of points, we can just pass it to `Jsonkit.Of_json.array` to get
a `point array decoder` in return.

#### Builders

To write a decoder _builder_ like `Jsonkit.Of_json.array` we need to take another
decoder as an argument, and thanks to currying we just need to apply it where
we'd otherwise use a fixed decoder. Say we want to be able to decode both `int
point`s and `float point`s. First we'd have to parameterize the type:

```reason
type point('a) = {
  x: 'a,
  y: 'a
}
```

Then we can change our `point` function from above to take and use a decoder
argument:

```reason
let point = (decodeNumber, json) => {
  open! Jsonkit.Decode;
  {
    x: json |> field("x", decodeNumber),
    y: json |> field("y", decodeNumber)
  };
};
```

And if we wish we can now create aliases for each variant:

```reason
let intPoint = point(Jsonkit.Of_json.int);
let floatPoint = point(Jsonkit.Of_json.float);
```

#### Encoders

Encoders work exactly the same way, just in reverse. `'a encoder` is just an
alias for `'a -> Js.Json.t`, and this also transfers to composition: `'a encoder
-> 'a array encoder` expands to `('a -> Js.Json.t) -> 'a array -> Js.Json.t`.

## PPX for Melange

A [ppx deriver
plugin](https://ocaml.org/docs/metaprogramming#attributes-and-derivers) is
provided to automatically convert Melange values to and from JSON.

### Installation

The PPX is included in the `jsonkit-melange` package. To use it, just add the
`dune` configuration to your project:

```dune
(library
 (modes melange)
 (preprocess (pps jsonkit-melange.ppx)))
```

### Usage

To generate JSON converters for a type, add the `[@@deriving json]` attribute to
the type declaration, ensuring the converters for primitives like `int` and
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
val of_json : Js.Json.t -> t
val to_json : t -> Js.Json.t
```

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

#### Generating JSON converters from type expressions

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

#### `[@json.default E]`: default values for records

You can specify default values for record fields using the `[@json.default E]`
attribute:

```ocaml
type t = {
  a: int;
  b: string [@json.default "-"];
} [@@deriving of_json]

let t = of_json (Jsonkit.of_string {|{"a": 42}|})
(* t = { a = 42; b = "-"; } *)
```

#### Extra fields on records

By default, both the native and Melange PPXs ignore JSON object keys that are
not part of the OCaml record type.

```ocaml
type t = {
  a: int;
} [@@deriving json]

let t = t_of_json (Jsonkit.of_string {|{"a": 42, "extra": "ignore me"}|})
(* t = { a = 42 } *)
```

`[@json.allow_extra_fields]` is still accepted for backwards compatibility, but
is no longer necessary.

Use `[@json.disallow_extra_fields]` to reject unknown keys and keep strict field
checking. This attribute can be used on regular records and on inline records in
variant constructors.

```ocaml
type strict = {
  a: int;
} [@@deriving json] [@@json.disallow_extra_fields]

let _ = strict_of_json (Jsonkit.of_string {|{"a": 42, "extra": "fail"}|})
(* raises: did not expect field "extra" *)
```

```ocaml
type strict_inline =
  | A of { a: int } [@json.disallow_extra_fields]
  [@@deriving json]

let _ =
  strict_inline_of_json
    (Jsonkit.of_string {|["A", {"a": 42, "extra": "fail"}]|})
(* raises: did not expect field "extra" *)
```

#### `[@json.option]`: a shortcut for `[@json.default None]`

When a field has type `_ option` then you can use the `[@json.option]` attribute
to specify that the default value is `None`:

```ocaml
type t = {
  a: int;
  b: string option [@json.option];
} [@@deriving of_json]

let t = of_json (Jsonkit.of_string {|{"a": 42}|})
(* t = { a = 42; b = None; } *)
```

#### `[@json.drop_default]`: drop default values from JSON

When a field has either `[@json.option]` or `[@json.default]` attributes, you can use the `[@json.drop_default]` 
attribute to make the generated `to_json` function drop the field
from the JSON output when its value matches the default.

In its flag form (no argument), `[@json.drop_default]` checks for `None` when used with
`[@json.option]`, and requires an `equal_<type>` function in scope when used with
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

For parameterized types, the equal function takes the inner type's `equal_<type>`
function as an argument, so a field of type `int list` generates a call to `equal_list equal_int`,
`int list list` generates `equal_list (equal_list equal_int)`, and so on.

```ocaml
let equal_int = Int.equal
let rec equal_list equal_a a b =
  match a, b with
  | [], [] -> true
  | x :: xs, y :: ys -> equal_a x y && equal_list equal_a xs ys
  | _ -> false

type t = {
  items: int list [@json.default []] [@json.drop_default];
} [@@deriving to_json]

let json = to_json { items = [] }
(* {} *)
```

You can also provide a custom comparison function of type `'a -> 'a -> bool` directly:

```ocaml
type t = {
  f: float [@json.default 0.0] [@json.drop_default Float.equal];
} [@@deriving to_json]

let json = to_json { f = 0.0 }
(* {} *)
```

#### `[@json.drop_default_if_json_equal]`: drop defaults by comparing JSON output

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

#### `[@json.key "S"]`: customizing keys for record fields

You can specify custom keys for record fields using the `[@json.key E]`
attribute:

```ocaml
type t = {
  a: int [@json.key "A"];
  b: string [@json.key "B"];
} [@@deriving of_json]

let t = of_json (Jsonkit.of_string {|{"A": 42, "B": "foo"}|})
(* t = { a = 42; b = "foo"; } *)
```

#### `[@json.name "S"]`: customizing the representation of a variant case

You can specify custom representation for a variant case using the `[@json.name
E]` attribute:

```ocaml
type t = A | B [@json.name "bbb"] [@@deriving json]

let json = to_json B
(* "bbb" *)
```

#### `[@@json.compact_variants]`: compact encoding for variants and polyvariants

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

#### `[@json.catch_all]`: catch-all constructor for unknown string tags

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

##### Wire shape mapping

`payload` distinguishes the wire shape so the value round-trips faithfully:

| Wire JSON               | Decoded                                                   | Re-encodes as          |
|-------------------------|-----------------------------------------------------------|------------------------|
| `"future_tag"`          | `{ tag = "future_tag"; payload = None }`                  | `"future_tag"`         |
| `["future_tag"]`        | `{ tag = "future_tag"; payload = Some [] }`               | `["future_tag"]`       |
| `["future_tag", 42]`    | `{ tag = "future_tag"; payload = Some [`Int 42] }`        | `["future_tag", 42]`   |

#### `[@@deriving json_string]`: a shortcut for JSON string conversion

For convenience, one can use `[@@deriving json_string]` to generate converters
directly to and from JSON strings:

```ocaml
type t = A [@@deriving json, json_string]

let "\"A\"" = to_json_string A
let A = of_json_string "\"A\""
```

Similarly, there's `[@@deriving to_json_string]` and `[@@deriving
of_json_string]` to generate the converters separately.

## PPX for OCaml native

A similar PPX is exposed in the `jsonkit` package, which works with
the `yojson` JSON representation instead of `Js.Json.t`.

### Installation

The PPX is included in `jsonkit` package, so that package will have
to be installed first:

```sh
opam install jsonkit
```

To use it, add the `dune` configuration to your project:

```dune
(executable
 ...
 (preprocess (pps jsonkit.ppx)))
```

### Usage

From the usage perspective, the PPX is similar to the Melange one:

```ocaml
type t = {
  a: int;
  b: string;
} [@@deriving json]
```

This will generate the following pair of functions:

```ocaml
val of_json : Yojson.Basic.json -> t
val to_json : t -> Yojson.Basic.json
```

Refer to the [PPX for Melange](#ppx-for-melange) section for more details on
usage patterns.

## JSON Schema (`[@@deriving jsonschema]`)

The PPX can generate a [JSON Schema](https://json-schema.org/) from a type with
`[@@deriving jsonschema]`. The schema matches the output produced by the
json derivers.

```ocaml
open Ppx_deriving_jsonschema_runtime.Primitives.Jsonkit

type t = {
  name: string;
  age: int;
} [@@deriving jsonschema]

let schema = Ppx_deriving_jsonschema_runtime.json_schema t_jsonschema
```

See **[JSONSCHEMA.md](./JSONSCHEMA.md)** for the full documentation: setup,
conversion rules, and all supported annotations.

## License

This work is dual-licensed under LGPL 3.0 and MPL 2.0. You can choose between
one of them if you use this work.

Please see LICENSE.LGPL-3.0 and LICENSE.MPL-2.0 for the full text of each
license.

`SPDX-License-Identifier: LGPL-3.0 OR MPL-2.0`
