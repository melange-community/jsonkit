Error reporting of [@@deriving jsonschema]. Structural errors on a type use
the "[@@deriving jsonschema]:" prefix; attribute errors name the attribute.

Some structural errors are placed in the expansion as [%ocaml.error] nodes
(the PPX itself succeeds, the compiler reports them), so we grep for them:

  $ cat > unsupported.ml << 'EOF'
  > type t = int -> int [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl unsupported.ml -o unsupported.actual.ml
  $ grep -o '"\[@@deriving jsonschema\][^"]*"' unsupported.actual.ml
  "[@@deriving jsonschema]: unsupported type int -> int"

  $ cat > abstract.ml << 'EOF'
  > type t [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl abstract.ml -o abstract.actual.ml
  $ grep -o '"\[@@deriving jsonschema\][^"]*"' abstract.actual.ml
  "[@@deriving jsonschema]: abstract type without manifest"

  $ cat > open.ml << 'EOF'
  > type t = .. [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl open.ml -o open.actual.ml
  $ grep -o '"\[@@deriving jsonschema\][^"]*"' open.actual.ml
  "[@@deriving jsonschema]: open types are not supported"

The remaining errors abort the expansion:

  $ cat > conjunctive.ml << 'EOF'
  > type t = [ `A of int & string ] [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl conjunctive.ml -o conjunctive.actual.ml
  File "conjunctive.ml", line 1, characters 9-31:
  1 | type t = [ `A of int & string ] [@@deriving jsonschema]
               ^^^^^^^^^^^^^^^^^^^^^^
  Error: [@@deriving jsonschema]: conjunctive polymorphic variant tags (`A of x & y) are not supported
  [1]

  $ cat > format_on_int.ml << 'EOF'
  > type t = { x : int [@jsonschema.format "date-time"] } [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl format_on_int.ml -o format_on_int.actual.ml
  File "format_on_int.ml", line 1, characters 15-18:
  1 | type t = { x : int [@jsonschema.format "date-time"] } [@@deriving jsonschema]
                     ^^^
  Error: [@jsonschema.format] can only be applied to string or bytes types
  [1]

  $ cat > maximum_on_string.ml << 'EOF'
  > type t = { x : string [@jsonschema.maximum 10] } [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl maximum_on_string.ml -o maximum_on_string.actual.ml
  File "maximum_on_string.ml", line 1, characters 15-21:
  1 | type t = { x : string [@jsonschema.maximum 10] } [@@deriving jsonschema]
                     ^^^^^^
  Error: [@jsonschema.maximum] can only be applied to numeric types
  [1]

  $ cat > maximum_not_literal.ml << 'EOF'
  > let limit = 10
  > type t = { x : int [@jsonschema.maximum limit] } [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl maximum_not_literal.ml -o maximum_not_literal.actual.ml
  File "maximum_not_literal.ml", line 2, characters 15-18:
  2 | type t = { x : int [@jsonschema.maximum limit] } [@@deriving jsonschema]
                     ^^^
  Error: [@jsonschema.maximum] can only be applied to numeric types
  [1]

  $ cat > attrs_unknown_field.ml << 'EOF'
  > type t = { x : int [@jsonschema.attrs { foo = 1 }] } [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl attrs_unknown_field.ml -o attrs_unknown_field.actual.ml
  File "attrs_unknown_field.ml", line 1, characters 40-43:
  1 | type t = { x : int [@jsonschema.attrs { foo = 1 }] } [@@deriving jsonschema]
                                              ^^^
  Error: [@jsonschema.attrs] unknown field: 'foo'
  [1]

  $ cat > attrs_not_record.ml << 'EOF'
  > type t = { x : int [@jsonschema.attrs 42] } [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl attrs_not_record.ml -o attrs_not_record.actual.ml
  File "attrs_not_record.ml", line 1, characters 38-40:
  1 | type t = { x : int [@jsonschema.attrs 42] } [@@deriving jsonschema]
                                            ^^
  Error: [@jsonschema.attrs] expects a record expression: { field = value; ... }
  [1]

  $ cat > attrs_format_no_type.ml << 'EOF'
  > type t = { x : int } [@@deriving jsonschema] [@@jsonschema.attrs { format = "date-time" }]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl attrs_format_no_type.ml -o attrs_format_no_type.actual.ml
  File "attrs_format_no_type.ml", line 1, characters 0-90:
  1 | type t = { x : int } [@@deriving jsonschema] [@@jsonschema.attrs { format = "date-time" }]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@jsonschema.attrs] 'format' requires a type context (use the individual [@jsonschema.format] attribute instead)
  [1]

  $ cat > default_on_arrow.ml << 'EOF'
  > type t = { f : int -> int [@jsonschema.default fun x -> x] } [@@deriving jsonschema]
  > EOF
  $ ./pp.exe -deriving-keep-w32 both --impl default_on_arrow.ml -o default_on_arrow.actual.ml
  File "default_on_arrow.ml", line 1, characters 15-25:
  1 | type t = { f : int -> int [@jsonschema.default fun x -> x] } [@@deriving jsonschema]
                     ^^^^^^^^^^
  Error: [@jsonschema.default] cannot serialize this type. For non-primitive types, ensure a '<type>_to_json' function is in scope (e.g., add [@@deriving json] to the type definition)
  [1]

  $ cat > format_on_record.ml << 'EOF2'
  > type t = { x : int } [@@deriving jsonschema] [@@jsonschema.format "date-time"]
  > EOF2
  $ ./pp.exe -deriving-keep-w32 both --impl format_on_record.ml -o format_on_record.actual.ml
  File "format_on_record.ml", line 1, characters 0-78:
  1 | type t = { x : int } [@@deriving jsonschema] [@@jsonschema.format "date-time"]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@jsonschema.format] requires a type declaration with a manifest (an alias), not a record or variant
  [1]

  $ cat > default_on_type_variable.ml << 'EOF2'
  > type 'a t = { x : 'a [@jsonschema.default 1] } [@@deriving jsonschema]
  > EOF2
  $ ./pp.exe -deriving-keep-w32 both --impl default_on_type_variable.ml -o default_on_type_variable.actual.ml
  File "default_on_type_variable.ml", line 1, characters 18-20:
  1 | type 'a t = { x : 'a [@jsonschema.default 1] } [@@deriving jsonschema]
                        ^^
  Error: [@jsonschema.default] cannot be used on a field whose type is a type variable
  [1]
