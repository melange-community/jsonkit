A handwritten converter with the wrong type used to fail unification deep
inside the generated encoder, pointing at the whole type declaration. The
generated code now ascribes every converter reference with the converter type
the deriver expects, so the error names the converter and points at the field
whose type it converts.

  $ cat > dune-project <<"EOF"
  > (lang dune 3.11)
  > (implicit_transitive_deps false)
  > (using melange 0.1)
  > EOF

  $ cat > dune <<"EOF"
  > (executable
  >  (name main)
  >  (modules main)
  >  (flags :standard -w -37-69 -open Jsonkit.Primitives)
  >  (preprocess (pps jsonkit.ppx)))
  > (library
  >  (name lib)
  >  (modes melange)
  >  (modules main_js)
  >  (libraries jsonkit-melange)
  >  (flags :standard -w -20-37-69 -open Jsonkit.Primitives)
  >  (preprocess (pps melange.ppx jsonkit-melange.ppx)))
  > (melange.emit
  >  (alias js)
  >  (target output)
  >  (modules)
  >  (libraries lib)
  >  (module_systems commonjs))
  > EOF

  $ build() { cp main.ml main_js.ml; dune build ./main.exe; dune build @js; }

The program from issue #69: [mytype_to_json] returns a string instead of JSON.

  $ cat > main.ml <<"EOF"
  > type mytype = Int64.t
  > 
  > let mytype_of_json json = Int64.of_float (Jsonkit.Of_json.float json)
  > let mytype_to_json i = Int64.to_string i
  > 
  > type my_record = { a : string; my_value : mytype; b : string }
  > [@@deriving json]
  > EOF

  $ build
  File "main.ml", line 6, characters 42-48:
  6 | type my_record = { a : string; my_value : mytype; b : string }
                                                ^^^^^^
  Error: The value mytype_to_json has type mytype -> string
         but an expression was expected of type mytype -> Yojson.Basic.t
         Type string is not compatible with type
           Yojson.Basic.t =
             [ `Assoc of (string * Yojson.Basic.t) list
             | `Bool of bool
             | `Float of float
             | `Int of int
             | `List of Yojson.Basic.t list
             | `Null
             | `String of string ]
  File "main_js.ml", line 6, characters 42-48:
  6 | type my_record = { a : string; my_value : mytype; b : string }
                                                ^^^^^^
  Error: The value mytype_to_json has type mytype -> string
         but an expression was expected of type mytype -> Js__Js_json.t
         Type string is not compatible with type Js__Js_json.t
  [1]

The same mistake under a type constructor still points at the field's own type.

  $ cat > main.ml <<"EOF"
  > type mytype = Int64.t
  > 
  > let mytype_of_json json = Int64.of_float (Jsonkit.Of_json.float json)
  > let mytype_to_json i = Int64.to_string i
  > 
  > type my_record = { my_values : mytype list } [@@deriving json]
  > EOF

  $ build
  File "main.ml", line 6, characters 31-37:
  6 | type my_record = { my_values : mytype list } [@@deriving json]
                                     ^^^^^^
  Error: The value mytype_to_json has type mytype -> string
         but an expression was expected of type mytype -> Yojson.Basic.t
         Type string is not compatible with type
           Yojson.Basic.t =
             [ `Assoc of (string * Yojson.Basic.t) list
             | `Bool of bool
             | `Float of float
             | `Int of int
             | `List of Yojson.Basic.t list
             | `Null
             | `String of string ]
  File "main_js.ml", line 6, characters 31-37:
  6 | type my_record = { my_values : mytype list } [@@deriving json]
                                     ^^^^^^
  Error: The value mytype_to_json has type mytype -> string
         but an expression was expected of type mytype -> Js__Js_json.t
         Type string is not compatible with type Js__Js_json.t
  [1]

A handwritten [of_json] taking the wrong argument type.

  $ cat > main.ml <<"EOF"
  > type mytype = Int64.t
  > 
  > let mytype_of_json s = Int64.of_string s
  > let mytype_to_json i = Jsonkit.To_json.string (Int64.to_string i)
  > 
  > type my_record = { my_value : mytype } [@@deriving json]
  > EOF

  $ build
  File "main.ml", line 6, characters 30-36:
  6 | type my_record = { my_value : mytype } [@@deriving json]
                                    ^^^^^^
  Error: The value mytype_of_json has type string -> mytype
         but an expression was expected of type Yojson.Basic.t -> mytype
         Type string is not compatible with type
           Yojson.Basic.t =
             [ `Assoc of (string * Yojson.Basic.t) list
             | `Bool of bool
             | `Float of float
             | `Int of int
             | `List of Yojson.Basic.t list
             | `Null
             | `String of string ]
  File "main_js.ml", line 6, characters 30-36:
  6 | type my_record = { my_value : mytype } [@@deriving json]
                                    ^^^^^^
  Error: The value mytype_of_json has type string -> mytype
         but an expression was expected of type Js__Js_json.t -> mytype
         Type string is not compatible with type Js__Js_json.t
  [1]
