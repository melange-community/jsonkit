When a type derives both [json] and [jsonschema], the attributes shared by
the two derivers must be written unqualified ([@key], not [@json.key]): the
qualified form is only seen by the deriver it names, so the generated schema
silently diverges from the JSON wire format. The linter warns on any
qualified shared attribute. Grepping for the message isolates the linter's
output from the derived code. The rule fires for both the native and the
browser ppx.

  $ cat > input.ml <<'EOF'
  > type record = {
  >   foo : int; [@json.key "foo_key"]
  >   bar : int option; [@jsonschema.option]
  >   baz : int; [@json.default 42]
  > }
  > [@@deriving json, jsonschema]
  > [@@jsonschema.allow_extra_fields]
  > 
  > type variant =
  >   | A [@json.name "a"]
  >   | B of { x : int [@jsonschema.key "y"] } [@json.allow_extra_fields]
  > [@@deriving json, jsonschema] [@@json.compact_variants]
  > 
  > type polyvariant = [ `A [@json.name "a"] ]
  > [@@deriving json, jsonschema]
  > EOF

  $ ../native/ppx_deriving_json_native_test.exe input.ml --use-compiler-pp 2>&1 | grep "melange-json linter"
    "melange-json linter: [@json.key] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@key] so it applies to both"]
    "melange-json linter: [@jsonschema.option] only applies to the jsonschema deriver, but this type derives both json and jsonschema; use the unqualified [@option] so it applies to both"]
    "melange-json linter: [@json.default] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@default] so it applies to both"]
    "melange-json linter: [@jsonschema.allow_extra_fields] only applies to the jsonschema deriver, but this type derives both json and jsonschema; use the unqualified [@allow_extra_fields] so it applies to both"]
    "melange-json linter: [@json.name] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@name] so it applies to both"]
    "melange-json linter: [@jsonschema.key] only applies to the jsonschema deriver, but this type derives both json and jsonschema; use the unqualified [@key] so it applies to both"]
    "melange-json linter: [@json.allow_extra_fields] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@allow_extra_fields] so it applies to both"]
    "melange-json linter: [@json.compact_variants] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@compact_variants] so it applies to both"]
    "melange-json linter: [@json.name] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@name] so it applies to both"]

  $ ../browser/ppx_deriving_json_js_test.exe input.ml --use-compiler-pp 2>&1 | grep "melange-json linter"
    "melange-json linter: [@json.key] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@key] so it applies to both"]
    "melange-json linter: [@jsonschema.option] only applies to the jsonschema deriver, but this type derives both json and jsonschema; use the unqualified [@option] so it applies to both"]
    "melange-json linter: [@json.default] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@default] so it applies to both"]
    "melange-json linter: [@jsonschema.allow_extra_fields] only applies to the jsonschema deriver, but this type derives both json and jsonschema; use the unqualified [@allow_extra_fields] so it applies to both"]
    "melange-json linter: [@json.name] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@name] so it applies to both"]
    "melange-json linter: [@jsonschema.key] only applies to the jsonschema deriver, but this type derives both json and jsonschema; use the unqualified [@key] so it applies to both"]
    "melange-json linter: [@json.allow_extra_fields] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@allow_extra_fields] so it applies to both"]
    "melange-json linter: [@json.compact_variants] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@compact_variants] so it applies to both"]
    "melange-json linter: [@json.name] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@name] so it applies to both"]

Qualified shared attributes are fine when only one of the two derivers is
used, unqualified shared attributes are always fine, and deriver-specific
attributes (e.g. [@jsonschema.description], [@json.drop_default]) may stay
qualified even when both derivers are used.

  $ cat > input.ml <<'EOF'
  > type json_only = {
  >   foo : int; [@json.key "foo_key"]
  > }
  > [@@deriving json]
  > 
  > type jsonschema_only = {
  >   foo : int; [@jsonschema.key "foo_key"]
  > }
  > [@@deriving jsonschema]
  > 
  > type unqualified = {
  >   foo : int; [@key "foo_key"]
  >   bar : int; [@jsonschema.description "doc"] [@default 42] [@json.drop_default]
  > }
  > [@@deriving json, jsonschema]
  > EOF

  $ ../native/ppx_deriving_json_native_test.exe input.ml --use-compiler-pp 2>&1 | grep "melange-json linter"
  [1]

  $ ../browser/ppx_deriving_json_js_test.exe input.ml --use-compiler-pp 2>&1 | grep "melange-json linter"
  [1]

In a recursive group, [@@deriving ...] is attached to a single declaration
but applies to the whole group, so the lint must cover every member of the
group, not just the one carrying the attribute.

  $ cat > input.ml <<'EOF'
  > type a = { x : int [@json.key "y"] }
  > and b = A of a [@jsonschema.name "a"]
  > [@@deriving json, jsonschema]
  > EOF

  $ ../native/ppx_deriving_json_native_test.exe input.ml --use-compiler-pp 2>&1 | grep "melange-json linter"
    "melange-json linter: [@json.key] only applies to the json deriver, but this type derives both json and jsonschema; use the unqualified [@key] so it applies to both"]
    "melange-json linter: [@jsonschema.name] only applies to the jsonschema deriver, but this type derives both json and jsonschema; use the unqualified [@name] so it applies to both"]

Deriver attributes used in a context they do not apply to are flagged,
whether qualified or not. Attributes are only matched against the
deriver(s) the type actually uses, so [@jsonschema.format] is ignored when
only [json] is derived.

  $ cat > input.ml <<'EOF'
  > type t = { foo : int [@json.name "a"] [@jsonschema.format "int32"] }
  > [@@deriving json]
  > 
  > type u = A [@key "k"] [@json.drop_default]
  > [@@deriving json, jsonschema] [@@json.default 1]
  > 
  > EOF

  $ ../native/ppx_deriving_json_native_test.exe input.ml --use-compiler-pp 2>&1 | grep "melange-json linter"
    "melange-json linter: [@json.name] is not allowed on a record field; it applies to variant constructors, polymorphic variant tags"]
    "melange-json linter: [@key] is not allowed on a variant constructor; it applies to record fields"]
    "melange-json linter: [@json.drop_default] is not allowed on a variant constructor; it applies to record fields"]
    "melange-json linter: [@json.default] is not allowed on a type declaration; it applies to record fields"]
