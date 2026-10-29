open Jsonkit.Primitives
module Mod1 =
  struct
    type m_1 =
      | A 
      | B [@@deriving jsonschema]
    include
      struct
        let m_1_jsonschema =
          `Assoc
            [("anyOf",
               (`List
                  [`Assoc
                     [("type", (`String "array"));
                     ("prefixItems",
                       (`List [`Assoc [("const", (`String "A"))]]));
                     ("unevaluatedItems", (`Bool false));
                     ("minItems", (`Int 1));
                     ("maxItems", (`Int 1))];
                  `Assoc
                    [("type", (`String "array"));
                    ("prefixItems",
                      (`List [`Assoc [("const", (`String "B"))]]));
                    ("unevaluatedItems", (`Bool false));
                    ("minItems", (`Int 1));
                    ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    module Mod2 =
      struct
        type m_2 =
          | C 
          | D [@@deriving jsonschema]
        include
          struct
            let m_2_jsonschema =
              `Assoc
                [("anyOf",
                   (`List
                      [`Assoc
                         [("type", (`String "array"));
                         ("prefixItems",
                           (`List [`Assoc [("const", (`String "C"))]]));
                         ("unevaluatedItems", (`Bool false));
                         ("minItems", (`Int 1));
                         ("maxItems", (`Int 1))];
                      `Assoc
                        [("type", (`String "array"));
                        ("prefixItems",
                          (`List [`Assoc [("const", (`String "D"))]]));
                        ("unevaluatedItems", (`Bool false));
                        ("minItems", (`Int 1));
                        ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
          end[@@ocaml.doc "@inline"][@@merlin.hide ]
      end
  end
type with_modules = {
  m: Mod1.m_1 ;
  m2: Mod1.Mod2.m_2 }[@@deriving jsonschema]
include
  struct
    let with_modules_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("m2", Mod1.Mod2.m_2_jsonschema);
                ("m", Mod1.m_1_jsonschema)]));
           ("required", (`List [`String "m2"; `String "m"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type kind =
  | Success 
  | Error 
  | Skipped [@name "skipped"][@@deriving jsonschema]
include
  struct
    let kind_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "Success"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List [`Assoc [("const", (`String "Error"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List [`Assoc [("const", (`String "skipped"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type poly_kind = [ `Aaa  | `Bbb  | `Ccc [@name "ccc"]][@@deriving jsonschema]
include
  struct
    let poly_kind_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "Aaa"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List [`Assoc [("const", (`String "Bbb"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List [`Assoc [("const", (`String "ccc"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type poly_kind_with_payload =
  [ `Aaa of int  | `Bbb  | `Ccc of (string * bool) [@name "ccc"]][@@deriving
                                                                   jsonschema]
include
  struct
    let poly_kind_with_payload_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "Aaa"))]; int_jsonschema]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List [`Assoc [("const", (`String "Bbb"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "ccc"))];
                     string_jsonschema;
                     bool_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 3));
                ("maxItems", (`Int 3))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type poly_inherit = [ `New_one  | `Second_one of int  | poly_kind][@@deriving
                                                                    jsonschema]
include
  struct
    let poly_inherit_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("anyOf",
              (`List
                 [`Assoc
                    [("type", (`String "array"));
                    ("prefixItems",
                      (`List [`Assoc [("const", (`String "New_one"))]]));
                    ("unevaluatedItems", (`Bool false));
                    ("minItems", (`Int 1));
                    ("maxItems", (`Int 1))];
                 `Assoc
                   [("type", (`String "array"));
                   ("prefixItems",
                     (`List
                        [`Assoc [("const", (`String "Second_one"))];
                        int_jsonschema]));
                   ("unevaluatedItems", (`Bool false));
                   ("minItems", (`Int 2));
                   ("maxItems", (`Int 2))];
                 poly_kind_jsonschema]))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type event =
  {
  date: float ;
  kind_f: kind ;
  comment: string ;
  opt: int option [@key "opt_int"];
  a: float array ;
  l: string list ;
  t: [ `Foo  | `Bar  | `Baz ] ;
  c: char ;
  bunch_of_bytes: bytes ;
  string_ref: string ref ;
  unit: unit ;
  native_int: nativeint }[@@deriving jsonschema]
include
  struct
    let event_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("native_int", int_jsonschema);
                ("unit", unit_jsonschema);
                ("string_ref", string_jsonschema);
                ("bunch_of_bytes", string_jsonschema);
                ("c", char_jsonschema);
                ("t",
                  (`Assoc
                     [("anyOf",
                        (`List
                           [`Assoc
                              [("type", (`String "array"));
                              ("prefixItems",
                                (`List [`Assoc [("const", (`String "Foo"))]]));
                              ("unevaluatedItems", (`Bool false));
                              ("minItems", (`Int 1));
                              ("maxItems", (`Int 1))];
                           `Assoc
                             [("type", (`String "array"));
                             ("prefixItems",
                               (`List [`Assoc [("const", (`String "Bar"))]]));
                             ("unevaluatedItems", (`Bool false));
                             ("minItems", (`Int 1));
                             ("maxItems", (`Int 1))];
                           `Assoc
                             [("type", (`String "array"));
                             ("prefixItems",
                               (`List [`Assoc [("const", (`String "Baz"))]]));
                             ("unevaluatedItems", (`Bool false));
                             ("minItems", (`Int 1));
                             ("maxItems", (`Int 1))]]))]));
                ("l", (list_jsonschema string_jsonschema));
                ("a", (array_jsonschema float_jsonschema));
                ("opt_int", (option_jsonschema int_jsonschema));
                ("comment", string_jsonschema);
                ("kind_f", kind_jsonschema);
                ("date", float_jsonschema)]));
           ("required",
             (`List
                [`String "native_int";
                `String "unit";
                `String "string_ref";
                `String "bunch_of_bytes";
                `String "c";
                `String "t";
                `String "l";
                `String "a";
                `String "opt_int";
                `String "comment";
                `String "kind_f";
                `String "date"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type recursive_record = {
  a: int ;
  b: recursive_record list }[@@deriving jsonschema]
include
  struct
    let recursive_record_jsonschema =
      let ppx_defs =
        [("recursive_record",
           (`Assoc
              [("type", (`String "object"));
              ("properties",
                (`Assoc
                   [("b",
                      (list_jsonschema
                         (`Assoc
                            [("$ref", (`String "#/$defs/recursive_record"))])));
                   ("a", int_jsonschema)]));
              ("required", (`List [`String "b"; `String "a"]));
              ("additionalProperties", (`Bool true))]))] in
      let recursive_record_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/recursive_record"))] in
      recursive_record_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type recursive_variant =
  | A of recursive_variant 
  | B [@@deriving jsonschema]
include
  struct
    let recursive_variant_jsonschema =
      let ppx_defs =
        [("recursive_variant",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List
                            [`Assoc [("const", (`String "A"))];
                            `Assoc
                              [("$ref",
                                 (`String "#/$defs/recursive_variant"))]]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List [`Assoc [("const", (`String "B"))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 1));
                      ("maxItems", (`Int 1))]]))]))] in
      let recursive_variant_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/recursive_variant"))] in
      recursive_variant_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type tree =
  | Leaf 
  | Node of {
  value: int ;
  left: tree ;
  right: tree } [@@deriving jsonschema]
include
  struct
    let tree_jsonschema =
      let ppx_defs =
        [("tree",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List [`Assoc [("const", (`String "Leaf"))]]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 1));
                       ("maxItems", (`Int 1))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "Node"))];
                           `Assoc
                             [("type", (`String "object"));
                             ("properties",
                               (`Assoc
                                  [("right",
                                     (`Assoc
                                        [("$ref", (`String "#/$defs/tree"))]));
                                  ("left",
                                    (`Assoc
                                       [("$ref", (`String "#/$defs/tree"))]));
                                  ("value", int_jsonschema)]));
                             ("required",
                               (`List
                                  [`String "right";
                                  `String "left";
                                  `String "value"]));
                             ("additionalProperties", (`Bool true))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]))] in
      let tree_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/tree"))] in
      tree_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type non_recursive = {
  x: int ;
  y: string }[@@deriving jsonschema]
include
  struct
    let non_recursive_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc [("y", string_jsonschema); ("x", int_jsonschema)]));
        ("required", (`List [`String "y"; `String "x"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type foo = {
  bar: bar option }
and bar = {
  foo: foo option }[@@deriving jsonschema]
include
  struct
    let (foo_jsonschema, bar_jsonschema) =
      let ppx_defs =
        [("foo",
           (`Assoc
              [("type", (`String "object"));
              ("properties",
                (`Assoc
                   [("bar",
                      (option_jsonschema
                         (`Assoc [("$ref", (`String "#/$defs/bar"))])))]));
              ("required", (`List [`String "bar"]));
              ("additionalProperties", (`Bool true))]));
        ("bar",
          (`Assoc
             [("type", (`String "object"));
             ("properties",
               (`Assoc
                  [("foo",
                     (option_jsonschema
                        (`Assoc [("$ref", (`String "#/$defs/foo"))])))]));
             ("required", (`List [`String "foo"]));
             ("additionalProperties", (`Bool true))]))] in
      let foo_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/foo"))] in
      let bar_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/bar"))] in
      (foo_jsonschema, bar_jsonschema)[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type expr =
  | Literal of int 
  | Binary of expr * expr 
  | Block of stmt list 
and stmt =
  | ExprStmt of expr 
  | IfStmt of {
  cond: expr ;
  then_: stmt ;
  else_: stmt option } [@@deriving jsonschema]
include
  struct
    let (expr_jsonschema, stmt_jsonschema) =
      let ppx_defs =
        [("expr",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List
                            [`Assoc [("const", (`String "Literal"))];
                            int_jsonschema]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "Binary"))];
                           `Assoc [("$ref", (`String "#/$defs/expr"))];
                           `Assoc [("$ref", (`String "#/$defs/expr"))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 3));
                      ("maxItems", (`Int 3))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "Block"))];
                           list_jsonschema
                             (`Assoc [("$ref", (`String "#/$defs/stmt"))])]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]));
        ("stmt",
          (`Assoc
             [("anyOf",
                (`List
                   [`Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "ExprStmt"))];
                           `Assoc [("$ref", (`String "#/$defs/expr"))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))];
                   `Assoc
                     [("type", (`String "array"));
                     ("prefixItems",
                       (`List
                          [`Assoc [("const", (`String "IfStmt"))];
                          `Assoc
                            [("type", (`String "object"));
                            ("properties",
                              (`Assoc
                                 [("else_",
                                    (option_jsonschema
                                       (`Assoc
                                          [("$ref", (`String "#/$defs/stmt"))])));
                                 ("then_",
                                   (`Assoc
                                      [("$ref", (`String "#/$defs/stmt"))]));
                                 ("cond",
                                   (`Assoc
                                      [("$ref", (`String "#/$defs/expr"))]))]));
                            ("required",
                              (`List
                                 [`String "else_";
                                 `String "then_";
                                 `String "cond"]));
                            ("additionalProperties", (`Bool true))]]));
                     ("unevaluatedItems", (`Bool false));
                     ("minItems", (`Int 2));
                     ("maxItems", (`Int 2))]]))]))] in
      let expr_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/expr"))] in
      let stmt_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/stmt"))] in
      (expr_jsonschema, stmt_jsonschema)[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type alpha = {
  x: int }
and beta = {
  y: string }[@@deriving jsonschema]
include
  struct
    let alpha_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties", (`Assoc [("x", int_jsonschema)]));
        ("required", (`List [`String "x"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
    let beta_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties", (`Assoc [("y", string_jsonschema)]));
        ("required", (`List [`String "y"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type node_a = {
  a: node_b option ;
  b: node_c option }
and node_b = {
  c: node_a option ;
  d: node_c option }
and node_c = {
  g: node_a option ;
  f: node_b option }[@@deriving jsonschema]
include
  struct
    let (node_a_jsonschema, node_b_jsonschema, node_c_jsonschema) =
      let ppx_defs =
        [("node_a",
           (`Assoc
              [("type", (`String "object"));
              ("properties",
                (`Assoc
                   [("b",
                      (option_jsonschema
                         (`Assoc [("$ref", (`String "#/$defs/node_c"))])));
                   ("a",
                     (option_jsonschema
                        (`Assoc [("$ref", (`String "#/$defs/node_b"))])))]));
              ("required", (`List [`String "b"; `String "a"]));
              ("additionalProperties", (`Bool true))]));
        ("node_b",
          (`Assoc
             [("type", (`String "object"));
             ("properties",
               (`Assoc
                  [("d",
                     (option_jsonschema
                        (`Assoc [("$ref", (`String "#/$defs/node_c"))])));
                  ("c",
                    (option_jsonschema
                       (`Assoc [("$ref", (`String "#/$defs/node_a"))])))]));
             ("required", (`List [`String "d"; `String "c"]));
             ("additionalProperties", (`Bool true))]));
        ("node_c",
          (`Assoc
             [("type", (`String "object"));
             ("properties",
               (`Assoc
                  [("f",
                     (option_jsonschema
                        (`Assoc [("$ref", (`String "#/$defs/node_b"))])));
                  ("g",
                    (option_jsonschema
                       (`Assoc [("$ref", (`String "#/$defs/node_a"))])))]));
             ("required", (`List [`String "f"; `String "g"]));
             ("additionalProperties", (`Bool true))]))] in
      let node_a_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/node_a"))] in
      let node_b_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/node_b"))] in
      let node_c_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/node_c"))] in
      (node_a_jsonschema, node_b_jsonschema, node_c_jsonschema)[@@warning
                                                                 "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type recursive_tuple =
  | Leaf of int 
  | Branch of (recursive_tuple * recursive_tuple) [@@deriving jsonschema]
include
  struct
    let recursive_tuple_jsonschema =
      let ppx_defs =
        [("recursive_tuple",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List
                            [`Assoc [("const", (`String "Leaf"))];
                            int_jsonschema]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "Branch"))];
                           `Assoc
                             [("type", (`String "array"));
                             ("prefixItems",
                               (`List
                                  [`Assoc
                                     [("$ref",
                                        (`String "#/$defs/recursive_tuple"))];
                                  `Assoc
                                    [("$ref",
                                       (`String "#/$defs/recursive_tuple"))]]));
                             ("unevaluatedItems", (`Bool false));
                             ("minItems", (`Int 2));
                             ("maxItems", (`Int 2))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]))] in
      let recursive_tuple_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/recursive_tuple"))] in
      recursive_tuple_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type int_tree = tree[@@deriving jsonschema]
include
  struct
    let int_tree_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive tree_jsonschema[@@warning
                                                             "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type events = event list[@@deriving jsonschema]
include
  struct
    let events_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (list_jsonschema event_jsonschema)[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type eventss = event list list[@@deriving jsonschema]
include
  struct
    let eventss_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (list_jsonschema (list_jsonschema event_jsonschema))[@@warning
                                                              "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type event_comment = (event * string)[@@deriving jsonschema]
include
  struct
    let event_comment_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "array"));
           ("prefixItems", (`List [event_jsonschema; string_jsonschema]));
           ("unevaluatedItems", (`Bool false));
           ("minItems", (`Int 2));
           ("maxItems", (`Int 2))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type event_comments' = event_comment list[@@deriving jsonschema]
include
  struct
    let event_comments'_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (list_jsonschema event_comment_jsonschema)[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type event_n = (event * int) list[@@deriving jsonschema]
include
  struct
    let event_n_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (list_jsonschema
           (`Assoc
              [("type", (`String "array"));
              ("prefixItems", (`List [event_jsonschema; int_jsonschema]));
              ("unevaluatedItems", (`Bool false));
              ("minItems", (`Int 2));
              ("maxItems", (`Int 2))]))[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type events_array = events array[@@deriving jsonschema]
include
  struct
    let events_array_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (array_jsonschema events_jsonschema)[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type numbers = int list[@@deriving jsonschema]
include
  struct
    let numbers_jsonschema = list_jsonschema int_jsonschema[@@warning
                                                             "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type opt = int option[@@deriving jsonschema]
include
  struct
    let opt_jsonschema = option_jsonschema int_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type using_m = {
  m: Mod1.m_1 }[@@deriving jsonschema]
include
  struct
    let using_m_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties", (`Assoc [("m", Mod1.m_1_jsonschema)]));
           ("required", (`List [`String "m"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type tuple_with_variant = (int * [ `A  | `B [@name "second_cstr"]])[@@deriving
                                                                    jsonschema]
include
  struct
    let tuple_with_variant_jsonschema =
      `Assoc
        [("type", (`String "array"));
        ("prefixItems",
          (`List
             [int_jsonschema;
             `Assoc
               [("anyOf",
                  (`List
                     [`Assoc
                        [("type", (`String "array"));
                        ("prefixItems",
                          (`List [`Assoc [("const", (`String "A"))]]));
                        ("unevaluatedItems", (`Bool false));
                        ("minItems", (`Int 1));
                        ("maxItems", (`Int 1))];
                     `Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List [`Assoc [("const", (`String "second_cstr"))]]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 1));
                       ("maxItems", (`Int 1))]]))]]));
        ("unevaluatedItems", (`Bool false));
        ("minItems", (`Int 2));
        ("maxItems", (`Int 2))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type player_scores =
  {
  player: string ;
  scores: numbers [@ref "numbers"][@key "scores_ref"]}[@@deriving jsonschema]
include
  struct
    let player_scores_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("scores_ref",
                (`Assoc [("$ref", (`String "#/$defs/numbers"))]));
             ("player", string_jsonschema)]));
        ("required", (`List [`String "scores_ref"; `String "player"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type address = {
  street: string ;
  city: string ;
  zip: string }[@@deriving jsonschema]
include
  struct
    let address_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("zip", string_jsonschema);
             ("city", string_jsonschema);
             ("street", string_jsonschema)]));
        ("required",
          (`List [`String "zip"; `String "city"; `String "street"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t = {
  name: string ;
  age: int ;
  email: string option ;
  address: address }[@@deriving jsonschema]
include
  struct
    let t_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("address", address_jsonschema);
                ("email", (option_jsonschema string_jsonschema));
                ("age", int_jsonschema);
                ("name", string_jsonschema)]));
           ("required",
             (`List
                [`String "address";
                `String "email";
                `String "age";
                `String "name"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type tt =
  {
  name: string ;
  age: int ;
  email: string option ;
  home_address: address [@ref "shared_address"];
  work_address: address [@ref "shared_address"];
  retreat_address: address [@ref "shared_address"]}[@@deriving jsonschema]
include
  struct
    let tt_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("retreat_address",
                (`Assoc [("$ref", (`String "#/$defs/shared_address"))]));
             ("work_address",
               (`Assoc [("$ref", (`String "#/$defs/shared_address"))]));
             ("home_address",
               (`Assoc [("$ref", (`String "#/$defs/shared_address"))]));
             ("email", (option_jsonschema string_jsonschema));
             ("age", int_jsonschema);
             ("name", string_jsonschema)]));
        ("required",
          (`List
             [`String "retreat_address";
             `String "work_address";
             `String "home_address";
             `String "email";
             `String "age";
             `String "name"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type c = char[@@deriving jsonschema]
include struct let c_jsonschema = char_jsonschema[@@warning "-32-39"] end
[@@ocaml.doc "@inline"][@@merlin.hide ]
type inline_record_with_extra_fields =
  | User of {
  name: string ;
  email: string } [@jsonschema.allow_extra_fields ]
  | Guest of {
  ip: string } [@@deriving jsonschema]
include
  struct
    let inline_record_with_extra_fields_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "User"))];
                      `Assoc
                        [("type", (`String "object"));
                        ("properties",
                          (`Assoc
                             [("email", string_jsonschema);
                             ("name", string_jsonschema)]));
                        ("required",
                          (`List [`String "email"; `String "name"]));
                        ("additionalProperties", (`Bool true))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "Guest"))];
                     `Assoc
                       [("type", (`String "object"));
                       ("properties", (`Assoc [("ip", string_jsonschema)]));
                       ("required", (`List [`String "ip"]));
                       ("additionalProperties", (`Bool true))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t1 =
  | Typ 
  | Class of string [@@deriving jsonschema]
include
  struct
    let t1_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "Typ"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "Class"))];
                     string_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t3 =
  | Typ [@name "type"]
  | Class of string [@name "class"][@@deriving jsonschema]
include
  struct
    let t3_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "type"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "class"))];
                     string_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t4 = (int * string)[@@deriving jsonschema]
include
  struct
    let t4_jsonschema =
      `Assoc
        [("type", (`String "array"));
        ("prefixItems", (`List [int_jsonschema; string_jsonschema]));
        ("unevaluatedItems", (`Bool false));
        ("minItems", (`Int 2));
        ("maxItems", (`Int 2))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t5 = [ `A of (int * string * bool) ][@@deriving jsonschema]
include
  struct
    let t5_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "A"))];
                      int_jsonschema;
                      string_jsonschema;
                      bool_jsonschema]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 4));
                 ("maxItems", (`Int 4))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t6 = [ `A of ((int * string * bool) * float) ][@@deriving jsonschema]
include
  struct
    let t6_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "A"))];
                      `Assoc
                        [("type", (`String "array"));
                        ("prefixItems",
                          (`List
                             [int_jsonschema;
                             string_jsonschema;
                             bool_jsonschema]));
                        ("unevaluatedItems", (`Bool false));
                        ("minItems", (`Int 3));
                        ("maxItems", (`Int 3))];
                      float_jsonschema]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 3));
                 ("maxItems", (`Int 3))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t7 =
  | A of int * string * bool [@@deriving jsonschema]
include
  struct
    let t7_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "A"))];
                      int_jsonschema;
                      string_jsonschema;
                      bool_jsonschema]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 4));
                 ("maxItems", (`Int 4))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t8 =
  | A of (int * string * bool) [@@deriving jsonschema]
include
  struct
    let t8_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "A"))];
                      `Assoc
                        [("type", (`String "array"));
                        ("prefixItems",
                          (`List
                             [int_jsonschema;
                             string_jsonschema;
                             bool_jsonschema]));
                        ("unevaluatedItems", (`Bool false));
                        ("minItems", (`Int 3));
                        ("maxItems", (`Int 3))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t9 =
  | A of (int * string * bool) * float [@@deriving jsonschema]
include
  struct
    let t9_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "A"))];
                      `Assoc
                        [("type", (`String "array"));
                        ("prefixItems",
                          (`List
                             [int_jsonschema;
                             string_jsonschema;
                             bool_jsonschema]));
                        ("unevaluatedItems", (`Bool false));
                        ("minItems", (`Int 3));
                        ("maxItems", (`Int 3))];
                      float_jsonschema]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 3));
                 ("maxItems", (`Int 3))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t10 = [ `A of (int * string * bool) ][@@deriving jsonschema]
include
  struct
    let t10_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "A"))];
                      int_jsonschema;
                      string_jsonschema;
                      bool_jsonschema]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 4));
                 ("maxItems", (`Int 4))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type t11 = [ `B of (int * string * bool) ][@@deriving
                                            jsonschema
                                              ~polymorphic_variant_tuple]
include
  struct
    let t11_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "B"))];
                      `Assoc
                        [("type", (`String "array"));
                        ("prefixItems",
                          (`List
                             [int_jsonschema;
                             string_jsonschema;
                             bool_jsonschema]));
                        ("unevaluatedItems", (`Bool false));
                        ("minItems", (`Int 3));
                        ("maxItems", (`Int 3))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type obj2 = {
  x: int }[@@deriving jsonschema][@@jsonschema.allow_extra_fields ]
include
  struct
    let obj2_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties", (`Assoc [("x", int_jsonschema)]));
        ("required", (`List [`String "x"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type obj1 = {
  obj2: obj2 }[@@deriving jsonschema]
include
  struct
    let obj1_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties", (`Assoc [("obj2", obj2_jsonschema)]));
           ("required", (`List [`String "obj2"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type nested_obj = {
  obj1: obj1 }[@@deriving jsonschema][@@allow_extra_fields ]
include
  struct
    let nested_obj_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties", (`Assoc [("obj1", obj1_jsonschema)]));
           ("required", (`List [`String "obj1"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type x_without_extra = {
  x: int }[@@deriving jsonschema][@@allow_extra_fields ]
include
  struct
    let x_without_extra_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties", (`Assoc [("x", int_jsonschema)]));
        ("required", (`List [`String "x"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type x_with_extra = {
  x: int ;
  y: int }[@@deriving jsonschema][@@allow_extra_fields ]
include
  struct
    let x_with_extra_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc [("y", int_jsonschema); ("x", int_jsonschema)]));
        ("required", (`List [`String "y"; `String "x"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type strict_obj = {
  x: int }[@@deriving jsonschema][@@jsonschema.disallow_extra_fields ]
include
  struct
    let strict_obj_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties", (`Assoc [("x", int_jsonschema)]));
        ("required", (`List [`String "x"]));
        ("additionalProperties", (`Bool false))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type inline_record_disallow_extra_fields =
  | User of {
  name: string ;
  email: string } [@jsonschema.disallow_extra_fields ]
  | Guest of {
  ip: string } [@@deriving jsonschema]
include
  struct
    let inline_record_disallow_extra_fields_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "User"))];
                      `Assoc
                        [("type", (`String "object"));
                        ("properties",
                          (`Assoc
                             [("email", string_jsonschema);
                             ("name", string_jsonschema)]));
                        ("required",
                          (`List [`String "email"; `String "name"]));
                        ("additionalProperties", (`Bool false))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "Guest"))];
                     `Assoc
                       [("type", (`String "object"));
                       ("properties", (`Assoc [("ip", string_jsonschema)]));
                       ("required", (`List [`String "ip"]));
                       ("additionalProperties", (`Bool true))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'url generic_link_traffic = {
  title: string option ;
  url: 'url }[@@deriving jsonschema]
include
  struct
    let generic_link_traffic_jsonschema url =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("url", url);
                ("title", (option_jsonschema string_jsonschema))]));
           ("required", (`List [`String "url"; `String "title"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type string_link_traffic = string generic_link_traffic[@@deriving jsonschema]
include
  struct
    let string_link_traffic_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (generic_link_traffic_jsonschema string_jsonschema)[@@warning
                                                             "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'a poly_variant =
  | A 
  | B of 'a [@@deriving jsonschema]
include
  struct
    let poly_variant_jsonschema a =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("anyOf",
              (`List
                 [`Assoc
                    [("type", (`String "array"));
                    ("prefixItems",
                      (`List [`Assoc [("const", (`String "A"))]]));
                    ("unevaluatedItems", (`Bool false));
                    ("minItems", (`Int 1));
                    ("maxItems", (`Int 1))];
                 `Assoc
                   [("type", (`String "array"));
                   ("prefixItems",
                     (`List [`Assoc [("const", (`String "B"))]; a]));
                   ("unevaluatedItems", (`Bool false));
                   ("minItems", (`Int 2));
                   ("maxItems", (`Int 2))]]))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type ('a, 'b) multi_param = {
  first: 'a ;
  second: 'b ;
  label: string }[@@deriving jsonschema]
include
  struct
    let multi_param_jsonschema a b =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("label", string_jsonschema); ("second", b); ("first", a)]));
           ("required",
             (`List [`String "label"; `String "second"; `String "first"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'a param_list = 'a list[@@deriving jsonschema]
include
  struct
    let param_list_jsonschema a =
      Jsonkit_jsonschema_defs.non_recursive (list_jsonschema a)[@@warning
                                                                 "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type ('a, 'b) either =
  | Left of 'a 
  | Right of 'b [@@deriving jsonschema]
include
  struct
    let either_jsonschema a b =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("anyOf",
              (`List
                 [`Assoc
                    [("type", (`String "array"));
                    ("prefixItems",
                      (`List [`Assoc [("const", (`String "Left"))]; a]));
                    ("unevaluatedItems", (`Bool false));
                    ("minItems", (`Int 2));
                    ("maxItems", (`Int 2))];
                 `Assoc
                   [("type", (`String "array"));
                   ("prefixItems",
                     (`List [`Assoc [("const", (`String "Right"))]; b]));
                   ("unevaluatedItems", (`Bool false));
                   ("minItems", (`Int 2));
                   ("maxItems", (`Int 2))]]))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type ('a, 'b) either_alias = ('a, 'b) either[@@deriving jsonschema]
include
  struct
    let either_alias_jsonschema a b =
      Jsonkit_jsonschema_defs.non_recursive (either_jsonschema a b)[@@warning
                                                                    "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type tool_params =
  {
  query: string [@jsonschema.description "The search query to execute"];
  max_results: int
    [@jsonschema.description "Maximum number of results to return"]}[@@deriving
                                                                    jsonschema]
include
  struct
    let tool_params_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("max_results",
                ((match int_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc
                        (("description",
                           (`String "Maximum number of results to return"))
                        :: ppx_fields)
                  | ppx_other -> ppx_other)));
             ("query",
               ((match string_jsonschema with
                 | `Assoc ppx_fields ->
                     `Assoc
                       (("description",
                          (`String "The search query to execute"))
                       :: ppx_fields)
                 | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "max_results"; `String "query"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type described_record =
  {
  name: string [@jsonschema.description "The user's full name"];
  age: int option
    [@jsonschema.option ][@jsonschema.description "The user's age"]}[@@deriving
                                                                    jsonschema]
[@@jsonschema.description "A user object"]
include
  struct
    let described_record_jsonschema =
      `Assoc
        [("description", (`String "A user object"));
        ("type", (`String "object"));
        ("properties",
          (`Assoc
             [("age",
                ((match option_jsonschema int_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc (("description", (`String "The user's age")) ::
                        ppx_fields)
                  | ppx_other -> ppx_other)));
             ("name",
               ((match string_jsonschema with
                 | `Assoc ppx_fields ->
                     `Assoc
                       (("description", (`String "The user's full name")) ::
                       ppx_fields)
                 | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "name"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type with_key_and_desc =
  {
  opt: int option
    [@key "opt_int"][@jsonschema.option ][@jsonschema.description
                                           "An optional integer"]}[@@deriving
                                                                    jsonschema]
include
  struct
    let with_key_and_desc_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("opt_int",
                ((match option_jsonschema int_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc
                        (("description", (`String "An optional integer")) ::
                        ppx_fields)
                  | ppx_other -> ppx_other)))]));
        ("required", (`List []));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type described_variant =
  | Plain [@jsonschema.description "No payload"]
  | With_int of int [@jsonschema.description "Single integer tag"]
  | Pair of string * int [@jsonschema.description "String and int"]
  | Description_value of ((string)[@jsonschema.description "A string value"]) 
[@@deriving jsonschema]
include
  struct
    let described_variant_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("description", (`String "No payload"));
                 ("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "Plain"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("description", (`String "Single integer tag"));
                ("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "With_int"))];
                     int_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))];
              `Assoc
                [("description", (`String "String and int"));
                ("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "Pair"))];
                     string_jsonschema;
                     int_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 3));
                ("maxItems", (`Int 3))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "Description_value"))];
                     (match string_jsonschema with
                      | `Assoc ppx_fields ->
                          `Assoc (("description", (`String "A string value"))
                            :: ppx_fields)
                      | ppx_other -> ppx_other)]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type described_variant_inline_record =
  | Point of {
  x: int ;
  y: int } [@jsonschema.description "A 2D point"][@@deriving jsonschema]
include
  struct
    let described_variant_inline_record_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("description", (`String "A 2D point"));
                 ("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "Point"))];
                      `Assoc
                        [("type", (`String "object"));
                        ("properties",
                          (`Assoc
                             [("y", int_jsonschema); ("x", int_jsonschema)]));
                        ("required", (`List [`String "y"; `String "x"]));
                        ("additionalProperties", (`Bool true))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_comment_record =
  {
  name: string [@ocaml.doc " The user's full name "];
  age: int [@ocaml.doc " The user's age "]}[@@deriving jsonschema ~ocaml_doc]
[@@ocaml.doc " A user object "]
include
  struct
    let doc_comment_record_jsonschema =
      `Assoc
        [("description", (`String "A user object"));
        ("type", (`String "object"));
        ("properties",
          (`Assoc
             [("age",
                ((match int_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc (("description", (`String "The user's age")) ::
                        ppx_fields)
                  | ppx_other -> ppx_other)));
             ("name",
               ((match string_jsonschema with
                 | `Assoc ppx_fields ->
                     `Assoc
                       (("description", (`String "The user's full name")) ::
                       ppx_fields)
                 | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "age"; `String "name"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_comment_disabled =
  {
  name: string [@ocaml.doc " The user's full name "]}[@@deriving jsonschema]
[@@ocaml.doc " A user object "]
include
  struct
    let doc_comment_disabled_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties", (`Assoc [("name", string_jsonschema)]));
        ("required", (`List [`String "name"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_comment_override =
  {
  field: string
    [@jsonschema.description "explicit wins"][@ocaml.doc " ocaml.doc loses "]}
[@@deriving jsonschema ~ocaml_doc]
include
  struct
    let doc_comment_override_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("field",
                ((match string_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc (("description", (`String "explicit wins")) ::
                        ppx_fields)
                  | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "field"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_comment_variant =
  | Plain [@ocaml.doc " No payload "]
  | With_int of int [@ocaml.doc " Single integer tag "][@@deriving
                                                         jsonschema
                                                           ~ocaml_doc]
include
  struct
    let doc_comment_variant_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("description", (`String "No payload"));
                 ("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "Plain"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("description", (`String "Single integer tag"));
                ("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "With_int"))];
                     int_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_comment_core_type = ((string)[@ocaml.doc " A string alias "])
[@@deriving jsonschema ~ocaml_doc]
include
  struct
    let doc_comment_core_type_jsonschema =
      match string_jsonschema with
      | `Assoc ppx_fields ->
          `Assoc (("description", (`String "A string alias")) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_attribute_alias = ((string)[@doc " Alias fallback "])[@@deriving
                                                                jsonschema
                                                                  ~ocaml_doc]
include
  struct
    let doc_attribute_alias_jsonschema =
      match string_jsonschema with
      | `Assoc ppx_fields ->
          `Assoc (("description", (`String "Alias fallback")) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
[@@@ocamlformat "disable"]
type doc_comment_multiline =
  {
  name: string
    [@ocaml.doc
      " The user's full name.\n          Must be non-empty and under 100 characters. "]}
[@@deriving jsonschema ~ocaml_doc]
include
  struct
    let doc_comment_multiline_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("name",
                ((match string_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc
                        (("description",
                           (`String
                              "The user's full name.\n          Must be non-empty and under 100 characters."))
                        :: ppx_fields)
                  | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "name"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
[@@@ocamlformat "enable"]
type doc_comment_poly_variant =
  [ `Plain [@ocaml.doc " No payload "]
  | `With_int of int [@ocaml.doc " Single integer tag "]][@@deriving
                                                           jsonschema
                                                             ~ocaml_doc]
include
  struct
    let doc_comment_poly_variant_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("description", (`String "No payload"));
                 ("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "Plain"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("description", (`String "Single integer tag"));
                ("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "With_int"))];
                     int_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_comment_multiple =
  ((string)[@ocaml.doc " first block "][@ocaml.doc " second block "][@doc
                                                                    " third block "])
[@@deriving jsonschema ~ocaml_doc]
include
  struct
    let doc_comment_multiple_jsonschema =
      match string_jsonschema with
      | `Assoc ppx_fields ->
          `Assoc
            (("description",
               (`String "first block\n\nsecond block\n\nthird block"))
            :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type doc_comment_poly_variant_override =
  [
    `Tagged
      [@jsonschema.description "explicit wins"][@ocaml.doc
                                                 " ocaml.doc loses "]]
[@@deriving jsonschema ~ocaml_doc]
include
  struct
    let doc_comment_poly_variant_override_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("description", (`String "explicit wins"));
                 ("type", (`String "array"));
                 ("prefixItems",
                   (`List [`Assoc [("const", (`String "Tagged"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type computation_result =
  | Ok 
  | Err of string [@@deriving jsonschema][@@jsonschema.description
                                           "Either success or an error message string"]
include
  struct
    let computation_result_jsonschema =
      `Assoc
        [("description",
           (`String "Either success or an error message string"));
        ("anyOf",
          (`List
             [`Assoc
                [("type", (`String "array"));
                ("prefixItems", (`List [`Assoc [("const", (`String "Ok"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))];
             `Assoc
               [("type", (`String "array"));
               ("prefixItems",
                 (`List
                    [`Assoc [("const", (`String "Err"))]; string_jsonschema]));
               ("unevaluatedItems", (`Bool false));
               ("minItems", (`Int 2));
               ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type nullable_fields =
  {
  plain: string option ;
  drop_simple: string option [@jsonschema.option ];
  drop_complex: int list option [@jsonschema.option ]}[@@deriving jsonschema]
include
  struct
    let nullable_fields_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("drop_complex",
                (option_jsonschema (list_jsonschema int_jsonschema)));
             ("drop_simple", (option_jsonschema string_jsonschema));
             ("plain", (option_jsonschema string_jsonschema))]));
        ("required", (`List [`String "plain"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type jsonkit_defaults =
  {
  required_value: int ;
  option_value: string option [@option ];
  option_default_none: string [@default None];
  default_none: string [@default None];
  default_value: string [@default "-"];
  dropped_option: int option [@option ][@drop_default ];
  dropped_default: int list [@default []][@drop_default ];
  custom_drop_default: float [@default 0.0][@drop_default Float.equal]}
[@@deriving jsonschema]
include
  struct
    let jsonkit_defaults_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("custom_drop_default",
                ((match float_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc (("default", (`Float 0.0)) :: ppx_fields)
                  | ppx_other -> ppx_other)));
             ("dropped_default",
               ((match list_jsonschema int_jsonschema with
                 | `Assoc ppx_fields ->
                     `Assoc (("default", (`List [])) :: ppx_fields)
                 | ppx_other -> ppx_other)));
             ("dropped_option", (option_jsonschema int_jsonschema));
             ("default_value",
               ((match string_jsonschema with
                 | `Assoc ppx_fields ->
                     `Assoc (("default", (`String "-")) :: ppx_fields)
                 | ppx_other -> ppx_other)));
             ("default_none",
               ((match string_jsonschema with
                 | `Assoc ppx_fields ->
                     `Assoc (("default", `Null) :: ppx_fields)
                 | ppx_other -> ppx_other)));
             ("option_default_none",
               ((match string_jsonschema with
                 | `Assoc ppx_fields ->
                     `Assoc (("default", `Null) :: ppx_fields)
                 | ppx_other -> ppx_other)));
             ("option_value", (option_jsonschema string_jsonschema));
             ("required_value", int_jsonschema)]));
        ("required", (`List [`String "required_value"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type composing_type = string
let composing_type_jsonschema =
  `Assoc
    [("type", (`String "string")); ("description", (`String "A string"))]
type composing_record =
  {
  composing_type: composing_type option [@jsonschema.option ]}[@@deriving
                                                                jsonschema]
include
  struct
    let composing_record_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("composing_type",
                   (option_jsonschema composing_type_jsonschema))]));
           ("required", (`List []));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type with_format = string[@@jsonschema.format "date-time"][@@deriving
                                                            jsonschema]
include
  struct
    let with_format_jsonschema =
      match string_jsonschema with
      | `Assoc ppx_fields ->
          `Assoc (("format", (`String "date-time")) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type with_format_record =
  {
  with_format: string [@jsonschema.format "date-time"]}[@@deriving
                                                         jsonschema]
include
  struct
    let with_format_record_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("with_format",
                ((match string_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc (("format", (`String "date-time")) ::
                        ppx_fields)
                  | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "with_format"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type with_format_variant =
  | A of
  ((string)[@jsonschema.format "date-time"][@jsonschema.description
                                             "A date-time string"])
  
  | B [@@deriving jsonschema]
include
  struct
    let with_format_variant_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "A"))];
                      (match match string_jsonschema with
                             | `Assoc ppx_fields ->
                                 `Assoc
                                   (("description",
                                      (`String "A date-time string"))
                                   :: ppx_fields)
                             | ppx_other -> ppx_other
                       with
                       | `Assoc ppx_fields ->
                           `Assoc (("format", (`String "date-time")) ::
                             ppx_fields)
                       | ppx_other -> ppx_other)]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems", (`List [`Assoc [("const", (`String "B"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'a grade' =
  | A of 'a 
  | B of ('a grade' * 'a grade') 
  | C 
type 'a grade = 'a grade' =
  | A of 'a 
  | B of ('a grade * 'a grade) 
  | C [@@deriving jsonschema]
include
  struct
    let grade_jsonschema =
      let ppx_defs_grade a =
        [("grade",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List [`Assoc [("const", (`String "A"))]; a]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "B"))];
                           `Assoc
                             [("type", (`String "array"));
                             ("prefixItems",
                               (`List
                                  [`Assoc
                                     [("$ref",
                                        (`String "#/$defs/\000Cases.grade"))];
                                  `Assoc
                                    [("$ref",
                                       (`String "#/$defs/\000Cases.grade"))]]));
                             ("unevaluatedItems", (`Bool false));
                             ("minItems", (`Int 2));
                             ("maxItems", (`Int 2))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List [`Assoc [("const", (`String "C"))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 1));
                      ("maxItems", (`Int 1))]]))]))] in
      let grade_jsonschema a =
        Jsonkit_jsonschema_defs.member "grade"
          (Jsonkit_jsonschema_defs.recursive_group ~path:"Cases"
             (ppx_defs_grade a)) in
      grade_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type self_ref = {
  children: self_ref list }[@@deriving jsonschema]
include
  struct
    let self_ref_jsonschema =
      let ppx_defs =
        [("self_ref",
           (`Assoc
              [("type", (`String "object"));
              ("properties",
                (`Assoc
                   [("children",
                      (list_jsonschema
                         (`Assoc [("$ref", (`String "#/$defs/self_ref"))])))]));
              ("required", (`List [`String "children"]));
              ("additionalProperties", (`Bool true))]))] in
      let self_ref_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/self_ref"))] in
      self_ref_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type two_self_refs = {
  a: self_ref ;
  b: self_ref }[@@deriving jsonschema]
include
  struct
    let two_self_refs_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc [("b", self_ref_jsonschema); ("a", self_ref_jsonschema)]));
           ("required", (`List [`String "b"; `String "a"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type ('atom, 'group_atom) filter =
  | Atom of 'atom 
  | Group of ('atom, 'group_atom) filter list * 'group_atom [@@deriving
                                                              jsonschema]
include
  struct
    let filter_jsonschema =
      let ppx_defs_filter atom group_atom =
        [("filter",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List [`Assoc [("const", (`String "Atom"))]; atom]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "Group"))];
                           list_jsonschema
                             (`Assoc
                                [("$ref",
                                   (`String "#/$defs/\000Cases.filter"))]);
                           group_atom]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 3));
                      ("maxItems", (`Int 3))]]))]))] in
      let filter_jsonschema atom group_atom =
        Jsonkit_jsonschema_defs.member "filter"
          (Jsonkit_jsonschema_defs.recursive_group ~path:"Cases"
             (ppx_defs_filter atom group_atom)) in
      filter_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type ('atom, 'group_atom) bool_filter =
  | BoolAtom of ('atom, 'group_atom) filter 
  | BoolFilterGroup of ('atom, 'group_atom) bool_filter list [@@deriving
                                                               jsonschema]
include
  struct
    let bool_filter_jsonschema =
      let ppx_defs_bool_filter atom group_atom =
        [("bool_filter",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List
                            [`Assoc [("const", (`String "BoolAtom"))];
                            filter_jsonschema atom group_atom]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "BoolFilterGroup"))];
                           list_jsonschema
                             (`Assoc
                                [("$ref",
                                   (`String "#/$defs/\000Cases.bool_filter"))])]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]))] in
      let bool_filter_jsonschema atom group_atom =
        Jsonkit_jsonschema_defs.member "bool_filter"
          (Jsonkit_jsonschema_defs.recursive_group ~path:"Cases"
             (ppx_defs_bool_filter atom group_atom)) in
      bool_filter_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'a rec_wrapper =
  | RWrap of 'a 
  | RNested of 'a rec_wrapper [@@deriving jsonschema]
include
  struct
    let rec_wrapper_jsonschema =
      let ppx_defs_rec_wrapper a =
        [("rec_wrapper",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List [`Assoc [("const", (`String "RWrap"))]; a]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "RNested"))];
                           `Assoc
                             [("$ref",
                                (`String "#/$defs/\000Cases.rec_wrapper"))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]))] in
      let rec_wrapper_jsonschema a =
        Jsonkit_jsonschema_defs.member "rec_wrapper"
          (Jsonkit_jsonschema_defs.recursive_group ~path:"Cases"
             (ppx_defs_rec_wrapper a)) in
      rec_wrapper_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type outer_rec =
  | ORLeaf of int 
  | ORNode of outer_rec rec_wrapper [@@deriving jsonschema]
include
  struct
    let outer_rec_jsonschema =
      let ppx_defs_outer_rec =
        [("outer_rec",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List
                            [`Assoc [("const", (`String "ORLeaf"))];
                            int_jsonschema]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "ORNode"))];
                           rec_wrapper_jsonschema
                             (`Assoc
                                [("$ref",
                                   (`String "#/$defs/\000Cases.outer_rec"))])]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]))] in
      let ppx_group =
        Jsonkit_jsonschema_defs.recursive_group ~path:"Cases"
          ppx_defs_outer_rec in
      let outer_rec_jsonschema =
        Jsonkit_jsonschema_defs.member "outer_rec" ppx_group in
      outer_rec_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type with_maximum = int[@@jsonschema.maximum 100][@@deriving jsonschema]
include
  struct
    let with_maximum_jsonschema =
      match int_jsonschema with
      | `Assoc ppx_fields -> `Assoc (("maximum", (`Int 100)) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type with_maximum_record = {
  field: int [@jsonschema.maximum 100]}[@@deriving jsonschema]
include
  struct
    let with_maximum_record_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("field",
                ((match int_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc (("maximum", (`Int 100)) :: ppx_fields)
                  | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "field"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type attrs_core_type =
  ((int)[@jsonschema.attrs
          {
            maximum = 100;
            minimum = 0;
            description = "Integer percentage value (0-100 inclusive)"
          }])[@@deriving jsonschema]
include
  struct
    let attrs_core_type_jsonschema =
      match match match int_jsonschema with
                  | `Assoc ppx_fields ->
                      `Assoc (("maximum", (`Int 100)) :: ppx_fields)
                  | ppx_other -> ppx_other
            with
            | `Assoc ppx_fields ->
                `Assoc (("minimum", (`Int 0)) :: ppx_fields)
            | ppx_other -> ppx_other
      with
      | `Assoc ppx_fields ->
          `Assoc
            (("description",
               (`String "Integer percentage value (0-100 inclusive)"))
            :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type attrs_record =
  {
  score: int
    [@jsonschema.attrs
      { maximum = 100; minimum = 0; description = "Score out of 100" }];
  label: string
    [@jsonschema.attrs
      { format = "date-time"; description = "An ISO date-time" }]}[@@deriving
                                                                    jsonschema]
include
  struct
    let attrs_record_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("label",
                ((match match string_jsonschema with
                        | `Assoc ppx_fields ->
                            `Assoc (("format", (`String "date-time")) ::
                              ppx_fields)
                        | ppx_other -> ppx_other
                  with
                  | `Assoc ppx_fields ->
                      `Assoc (("description", (`String "An ISO date-time"))
                        :: ppx_fields)
                  | ppx_other -> ppx_other)));
             ("score",
               ((match match match int_jsonschema with
                             | `Assoc ppx_fields ->
                                 `Assoc (("maximum", (`Int 100)) ::
                                   ppx_fields)
                             | ppx_other -> ppx_other
                       with
                       | `Assoc ppx_fields ->
                           `Assoc (("minimum", (`Int 0)) :: ppx_fields)
                       | ppx_other -> ppx_other
                 with
                 | `Assoc ppx_fields ->
                     `Assoc (("description", (`String "Score out of 100")) ::
                       ppx_fields)
                 | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "label"; `String "score"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type attrs_type_decl = int[@@jsonschema.attrs
                            { description = "A plain integer" }][@@deriving
                                                                  jsonschema]
include
  struct
    let attrs_type_decl_jsonschema =
      match int_jsonschema with
      | `Assoc ppx_fields ->
          `Assoc (("description", (`String "A plain integer")) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type minimum_core_type_int =
  ((int)[@jsonschema.minimum 0][@jsonschema.maximum 100])[@@deriving
                                                           jsonschema]
include
  struct
    let minimum_core_type_int_jsonschema =
      match match int_jsonschema with
            | `Assoc ppx_fields ->
                `Assoc (("maximum", (`Int 100)) :: ppx_fields)
            | ppx_other -> ppx_other
      with
      | `Assoc ppx_fields -> `Assoc (("minimum", (`Int 0)) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type minimum_core_type_float =
  ((float)[@jsonschema.minimum 0.0][@jsonschema.maximum 1.0])[@@deriving
                                                               jsonschema]
include
  struct
    let minimum_core_type_float_jsonschema =
      match match float_jsonschema with
            | `Assoc ppx_fields ->
                `Assoc (("maximum", (`Float 1.0)) :: ppx_fields)
            | ppx_other -> ppx_other
      with
      | `Assoc ppx_fields -> `Assoc (("minimum", (`Float 0.0)) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type minimum_maximum_record =
  {
  score: int [@jsonschema.minimum 0][@jsonschema.maximum 100];
  ratio: float [@jsonschema.minimum 0.0][@jsonschema.maximum 1.0]}[@@deriving
                                                                    jsonschema]
include
  struct
    let minimum_maximum_record_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc
             [("ratio",
                ((match match float_jsonschema with
                        | `Assoc ppx_fields ->
                            `Assoc (("maximum", (`Float 1.0)) :: ppx_fields)
                        | ppx_other -> ppx_other
                  with
                  | `Assoc ppx_fields ->
                      `Assoc (("minimum", (`Float 0.0)) :: ppx_fields)
                  | ppx_other -> ppx_other)));
             ("score",
               ((match match int_jsonschema with
                       | `Assoc ppx_fields ->
                           `Assoc (("maximum", (`Int 100)) :: ppx_fields)
                       | ppx_other -> ppx_other
                 with
                 | `Assoc ppx_fields ->
                     `Assoc (("minimum", (`Int 0)) :: ppx_fields)
                 | ppx_other -> ppx_other)))]));
        ("required", (`List [`String "ratio"; `String "score"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type minimum_maximum_type_decl_int = int[@@jsonschema.minimum 0][@@jsonschema.maximum
                                                                  255]
[@@deriving jsonschema]
include
  struct
    let minimum_maximum_type_decl_int_jsonschema =
      match match int_jsonschema with
            | `Assoc ppx_fields ->
                `Assoc (("maximum", (`Int 255)) :: ppx_fields)
            | ppx_other -> ppx_other
      with
      | `Assoc ppx_fields -> `Assoc (("minimum", (`Int 0)) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type minimum_maximum_type_decl_float = float[@@jsonschema.minimum 0.0]
[@@jsonschema.maximum 1.0][@@deriving jsonschema]
include
  struct
    let minimum_maximum_type_decl_float_jsonschema =
      match match float_jsonschema with
            | `Assoc ppx_fields ->
                `Assoc (("maximum", (`Float 1.0)) :: ppx_fields)
            | ppx_other -> ppx_other
      with
      | `Assoc ppx_fields -> `Assoc (("minimum", (`Float 0.0)) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type minimum_maximum_variant =
  | Percentage of ((int)[@jsonschema.minimum 0][@jsonschema.maximum 100]) 
  | Factor of ((float)[@jsonschema.minimum 0.0][@jsonschema.maximum 1.0]) 
[@@deriving jsonschema]
include
  struct
    let minimum_maximum_variant_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems",
                   (`List
                      [`Assoc [("const", (`String "Percentage"))];
                      (match match int_jsonschema with
                             | `Assoc ppx_fields ->
                                 `Assoc (("maximum", (`Int 100)) ::
                                   ppx_fields)
                             | ppx_other -> ppx_other
                       with
                       | `Assoc ppx_fields ->
                           `Assoc (("minimum", (`Int 0)) :: ppx_fields)
                       | ppx_other -> ppx_other)]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 2));
                 ("maxItems", (`Int 2))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "Factor"))];
                     (match match float_jsonschema with
                            | `Assoc ppx_fields ->
                                `Assoc (("maximum", (`Float 1.0)) ::
                                  ppx_fields)
                            | ppx_other -> ppx_other
                      with
                      | `Assoc ppx_fields ->
                          `Assoc (("minimum", (`Float 0.0)) :: ppx_fields)
                      | ppx_other -> ppx_other)]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type variant_for_default =
  | A 
  | B [@@deriving (to_json, jsonschema)]
include
  struct
    [@@@ocaml.warning "-39-11-27"]
    let rec variant_for_default_to_json =
      (fun x ->
         match x with
         | A -> (Obj.magic [|(Obj.magic "A" : Js.Json.t)|] : Js.Json.t)
         | B -> (Obj.magic [|(Obj.magic "B" : Js.Json.t)|] : Js.Json.t) : 
      variant_for_default -> Js.Json.t)
    let variant_for_default_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc
                 [("type", (`String "array"));
                 ("prefixItems", (`List [`Assoc [("const", (`String "A"))]]));
                 ("unevaluatedItems", (`Bool false));
                 ("minItems", (`Int 1));
                 ("maxItems", (`Int 1))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems", (`List [`Assoc [("const", (`String "B"))]]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 1));
                ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'a range = {
  from: 'a ;
  to_: 'a [@key "to"]}[@@deriving (to_json, jsonschema)]
include
  struct
    [@@@ocaml.warning "-39-11-27"]
    let rec range_to_json a_to_json =
      (fun x ->
         match x with
         | { from = x_from; to_ = x_to_ } ->
             (Obj.magic
                (let module J =
                   struct
                     external unsafe_expr :
                       from:'a0 ->
                         \#to:'a1 -> < from: 'a0  ;\#to: 'a1   >  Js.t = ""
                         ""[@@ocaml.warning "-unboxable-type-in-prim-decl"]
                     [@@mel.internal.ffi
                       "\132\149\166\190\000\000\000\018\000\000\000\t\000\000\000\023\000\000\000\022\145\160\160A\144$from\160\160A\144\"to@"]
                   end in
                   J.unsafe_expr ~from:(a_to_json x_from)
                     ~\#to:(a_to_json x_to_)) : Js.Json.t) : 'a range ->
                                                               Js.Json.t)
    let range_jsonschema a =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties", (`Assoc [("to", a); ("from", a)]));
           ("required", (`List [`String "to"; `String "from"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type record_for_default = {
  score: int option }[@@deriving (to_json, jsonschema)]
include
  struct
    [@@@ocaml.warning "-39-11-27"]
    let rec record_for_default_to_json =
      (fun x ->
         match x with
         | { score = x_score } ->
             (Obj.magic
                (let module J =
                   struct
                     external unsafe_expr :
                       score:'a0 -> < score: 'a0   >  Js.t = "" ""[@@ocaml.warning
                                                                    "-unboxable-type-in-prim-decl"]
                     [@@mel.internal.ffi
                       "\132\149\166\190\000\000\000\012\000\000\000\005\000\000\000\r\000\000\000\012\145\160\160A\144%score@"]
                   end in
                   J.unsafe_expr
                     ~score:((option_to_json int_to_json) x_score)) : 
             Js.Json.t) : record_for_default -> Js.Json.t)
    let record_for_default_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc [("score", (option_jsonschema int_jsonschema))]));
        ("required", (`List [`String "score"]));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type default_value =
  {
  score: int option [@default 0];
  label: string [@jsonschema.default "default"];
  speed: float [@jsonschema.default 100.0];
  is_active: bool [@jsonschema.default false];
  pair: (int * string) [@jsonschema.default (1, "hello")];
  pairs: (string * string option) list
    [@default [("a", None); ("b", (Some "b"))]];
  variant: variant_for_default [@jsonschema.default A];
  record: record_for_default [@jsonschema.default { score = None }];
  int_list: int list [@jsonschema.default [1; 2; 3]];
  empty_list: int list [@jsonschema.default []];
  range: int range [@jsonschema.default { from = 0; to_ = 100 }]}[@@deriving
                                                                   jsonschema]
include
  struct
    let default_value_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("range",
                   ((match range_jsonschema int_jsonschema with
                     | `Assoc ppx_fields ->
                         `Assoc
                           (("default",
                              (Jsonkit.Jsonschema.classify
                                 ((range_to_json
                                     (fun ppx_x ->
                                        Jsonkit.Jsonschema.declassify
                                          (`Int ppx_x)))
                                    { from = 0; to_ = 100 })))
                           :: ppx_fields)
                     | ppx_other -> ppx_other)));
                ("empty_list",
                  ((match list_jsonschema int_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc (("default", (`List [])) :: ppx_fields)
                    | ppx_other -> ppx_other)));
                ("int_list",
                  ((match list_jsonschema int_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc
                          (("default",
                             (`List
                                (Stdlib.List.map
                                   (fun ppx_item -> `Int ppx_item) [1; 2; 3])))
                          :: ppx_fields)
                    | ppx_other -> ppx_other)));
                ("record",
                  ((match record_for_default_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc
                          (("default",
                             (Jsonkit.Jsonschema.classify
                                (record_for_default_to_json { score = None })))
                          :: ppx_fields)
                    | ppx_other -> ppx_other)));
                ("variant",
                  ((match variant_for_default_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc
                          (("default",
                             (Jsonkit.Jsonschema.classify
                                (variant_for_default_to_json A)))
                          :: ppx_fields)
                    | ppx_other -> ppx_other)));
                ("pairs",
                  ((match list_jsonschema
                            (`Assoc
                               [("type", (`String "array"));
                               ("prefixItems",
                                 (`List
                                    [string_jsonschema;
                                    option_jsonschema string_jsonschema]));
                               ("unevaluatedItems", (`Bool false));
                               ("minItems", (`Int 2));
                               ("maxItems", (`Int 2))])
                    with
                    | `Assoc ppx_fields ->
                        `Assoc
                          (("default",
                             (`List
                                (Stdlib.List.map
                                   (fun ppx_item ->
                                      match ppx_item with
                                      | (ppx_tuple_0, ppx_tuple_1) ->
                                          `List
                                            [`String ppx_tuple_0;
                                            (match ppx_tuple_1 with
                                             | None -> `Null
                                             | Some ppx_opt_v ->
                                                 `String ppx_opt_v)])
                                   [("a", None); ("b", (Some "b"))])))
                          :: ppx_fields)
                    | ppx_other -> ppx_other)));
                ("pair",
                  (`Assoc
                     [("default",
                        ((match (1, "hello") with
                          | (ppx_tuple_0, ppx_tuple_1) ->
                              `List [`Int ppx_tuple_0; `String ppx_tuple_1])));
                     ("type", (`String "array"));
                     ("prefixItems",
                       (`List [int_jsonschema; string_jsonschema]));
                     ("unevaluatedItems", (`Bool false));
                     ("minItems", (`Int 2));
                     ("maxItems", (`Int 2))]));
                ("is_active",
                  ((match bool_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc (("default", (`Bool false)) :: ppx_fields)
                    | ppx_other -> ppx_other)));
                ("speed",
                  ((match float_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc (("default", (`Float 100.0)) :: ppx_fields)
                    | ppx_other -> ppx_other)));
                ("label",
                  ((match string_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc (("default", (`String "default")) ::
                          ppx_fields)
                    | ppx_other -> ppx_other)));
                ("score",
                  ((match option_jsonschema int_jsonschema with
                    | `Assoc ppx_fields ->
                        `Assoc (("default", (`Int 0)) :: ppx_fields)
                    | ppx_other -> ppx_other)))]));
           ("required", (`List []));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
module Status =
  struct
    type t =
      | Active 
      | Inactive [@@deriving (to_json, jsonschema)]
    include
      struct
        [@@@ocaml.warning "-39-11-27"]
        let rec to_json =
          (fun x ->
             match x with
             | Active ->
                 (Obj.magic [|(Obj.magic "Active" : Js.Json.t)|] : Js.Json.t)
             | Inactive ->
                 (Obj.magic [|(Obj.magic "Inactive" : Js.Json.t)|] : 
                 Js.Json.t) : t -> Js.Json.t)
        let t_jsonschema =
          `Assoc
            [("anyOf",
               (`List
                  [`Assoc
                     [("type", (`String "array"));
                     ("prefixItems",
                       (`List [`Assoc [("const", (`String "Active"))]]));
                     ("unevaluatedItems", (`Bool false));
                     ("minItems", (`Int 1));
                     ("maxItems", (`Int 1))];
                  `Assoc
                    [("type", (`String "array"));
                    ("prefixItems",
                      (`List [`Assoc [("const", (`String "Inactive"))]]));
                    ("unevaluatedItems", (`Bool false));
                    ("minItems", (`Int 1));
                    ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
  end
type default_with_module_type =
  {
  status: Status.t [@jsonschema.default Status.Active]}[@@deriving
                                                         jsonschema]
include
  struct
    let default_with_module_type_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("status",
                   ((match Status.t_jsonschema with
                     | `Assoc ppx_fields ->
                         `Assoc
                           (("default",
                              (Jsonkit.Jsonschema.classify
                                 (Status.to_json Status.Active)))
                           :: ppx_fields)
                     | ppx_other -> ppx_other)))]));
           ("required", (`List []));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type inner_with_option_field = {
  foo: int option [@option ][@drop_default ]}[@@deriving
                                               (to_json, jsonschema)]
include
  struct
    [@@@ocaml.warning "-39-11-27"]
    let rec inner_with_option_field_to_json =
      (fun x ->
         match x with
         | { foo = x_foo } ->
             (Obj.magic
                (let module J =
                   struct
                     external unsafe_expr :
                       foo:'a0 -> < foo: 'a0   >  Js.t = "" ""[@@ocaml.warning
                                                                "-unboxable-type-in-prim-decl"]
                     [@@mel.internal.ffi
                       "\132\149\166\190\000\000\000\n\000\000\000\005\000\000\000\012\000\000\000\012\145\160\160A\144#foo@"]
                   end in
                   J.unsafe_expr
                     ~foo:(match x_foo with
                           | Stdlib.Option.None -> Js.Undefined.empty
                           | Stdlib.Option.Some _ ->
                               Js.Undefined.return
                                 ((option_to_json int_to_json) x_foo))) : 
             Js.Json.t) : inner_with_option_field -> Js.Json.t)
    let inner_with_option_field_jsonschema =
      `Assoc
        [("type", (`String "object"));
        ("properties",
          (`Assoc [("foo", (option_jsonschema int_jsonschema))]));
        ("required", (`List []));
        ("additionalProperties", (`Bool true))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
let empty_inner_with_option_field : inner_with_option_field = { foo = None }
type outer_default_record_with_option =
  {
  inner: inner_with_option_field [@default empty_inner_with_option_field]}
[@@deriving jsonschema]
include
  struct
    let outer_default_record_with_option_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("inner",
                   ((match inner_with_option_field_jsonschema with
                     | `Assoc ppx_fields ->
                         `Assoc
                           (("default",
                              (Jsonkit.Jsonschema.classify
                                 (inner_with_option_field_to_json
                                    empty_inner_with_option_field)))
                           :: ppx_fields)
                     | ppx_other -> ppx_other)))]));
           ("required", (`List []));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type compact_variants =
  | A 
  | B 
  | C of int [@@deriving jsonschema][@@jsonschema.compact_variants ]
include
  struct
    let compact_variants_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc [("const", (`String "A"))];
              `Assoc [("const", (`String "B"))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List [`Assoc [("const", (`String "C"))]; int_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type compact_poly_variants = [ `Aaa  | `Bbb  | `Ccc of int ][@@deriving
                                                              jsonschema]
[@@jsonschema.compact_variants ]
include
  struct
    let compact_poly_variants_jsonschema =
      `Assoc
        [("anyOf",
           (`List
              [`Assoc [("const", (`String "Aaa"))];
              `Assoc [("const", (`String "Bbb"))];
              `Assoc
                [("type", (`String "array"));
                ("prefixItems",
                  (`List
                     [`Assoc [("const", (`String "Ccc"))]; int_jsonschema]));
                ("unevaluatedItems", (`Bool false));
                ("minItems", (`Int 2));
                ("maxItems", (`Int 2))]]))][@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
module Generated_code_must_qualify_stdlib =
  struct
    module List = struct  end
    module String = struct  end
    module Array = struct  end
    type plain_variant_with_shadowed_stdlib =
      | A 
      | B [@name "b"][@@deriving jsonschema]
    include
      struct
        let plain_variant_with_shadowed_stdlib_jsonschema =
          `Assoc
            [("anyOf",
               (`List
                  [`Assoc
                     [("type", (`String "array"));
                     ("prefixItems",
                       (`List [`Assoc [("const", (`String "A"))]]));
                     ("unevaluatedItems", (`Bool false));
                     ("minItems", (`Int 1));
                     ("maxItems", (`Int 1))];
                  `Assoc
                    [("type", (`String "array"));
                    ("prefixItems",
                      (`List [`Assoc [("const", (`String "b"))]]));
                    ("unevaluatedItems", (`Bool false));
                    ("minItems", (`Int 1));
                    ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    type 'a wrapper_with_shadowed_stdlib =
      | Wrap of 'a 
      | Nested of 'a wrapper_with_shadowed_stdlib [@@deriving jsonschema]
    include
      struct
        let wrapper_with_shadowed_stdlib_jsonschema =
          let ppx_defs_wrapper_with_shadowed_stdlib a =
            [("wrapper_with_shadowed_stdlib",
               (`Assoc
                  [("anyOf",
                     (`List
                        [`Assoc
                           [("type", (`String "array"));
                           ("prefixItems",
                             (`List [`Assoc [("const", (`String "Wrap"))]; a]));
                           ("unevaluatedItems", (`Bool false));
                           ("minItems", (`Int 2));
                           ("maxItems", (`Int 2))];
                        `Assoc
                          [("type", (`String "array"));
                          ("prefixItems",
                            (`List
                               [`Assoc [("const", (`String "Nested"))];
                               `Assoc
                                 [("$ref",
                                    (`String
                                       "#/$defs/\000Cases.Generated_code_must_qualify_stdlib.wrapper_with_shadowed_stdlib"))]]));
                          ("unevaluatedItems", (`Bool false));
                          ("minItems", (`Int 2));
                          ("maxItems", (`Int 2))]]))]))] in
          let wrapper_with_shadowed_stdlib_jsonschema a =
            Jsonkit_jsonschema_defs.member "wrapper_with_shadowed_stdlib"
              (Jsonkit_jsonschema_defs.recursive_group
                 ~path:"Cases.Generated_code_must_qualify_stdlib"
                 (ppx_defs_wrapper_with_shadowed_stdlib a)) in
          wrapper_with_shadowed_stdlib_jsonschema[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    type rec_using_wrapper_with_shadowed_stdlib =
      | Leaf of int 
      | Node of rec_using_wrapper_with_shadowed_stdlib
      wrapper_with_shadowed_stdlib [@@deriving jsonschema]
    include
      struct
        let rec_using_wrapper_with_shadowed_stdlib_jsonschema =
          let ppx_defs_rec_using_wrapper_with_shadowed_stdlib =
            [("rec_using_wrapper_with_shadowed_stdlib",
               (`Assoc
                  [("anyOf",
                     (`List
                        [`Assoc
                           [("type", (`String "array"));
                           ("prefixItems",
                             (`List
                                [`Assoc [("const", (`String "Leaf"))];
                                int_jsonschema]));
                           ("unevaluatedItems", (`Bool false));
                           ("minItems", (`Int 2));
                           ("maxItems", (`Int 2))];
                        `Assoc
                          [("type", (`String "array"));
                          ("prefixItems",
                            (`List
                               [`Assoc [("const", (`String "Node"))];
                               wrapper_with_shadowed_stdlib_jsonschema
                                 (`Assoc
                                    [("$ref",
                                       (`String
                                          "#/$defs/\000Cases.Generated_code_must_qualify_stdlib.rec_using_wrapper_with_shadowed_stdlib"))])]));
                          ("unevaluatedItems", (`Bool false));
                          ("minItems", (`Int 2));
                          ("maxItems", (`Int 2))]]))]))] in
          let ppx_group =
            Jsonkit_jsonschema_defs.recursive_group
              ~path:"Cases.Generated_code_must_qualify_stdlib"
              ppx_defs_rec_using_wrapper_with_shadowed_stdlib in
          let rec_using_wrapper_with_shadowed_stdlib_jsonschema =
            Jsonkit_jsonschema_defs.member
              "rec_using_wrapper_with_shadowed_stdlib" ppx_group in
          rec_using_wrapper_with_shadowed_stdlib_jsonschema[@@warning
                                                             "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    type record_with_default_with_shadowed_stdlib =
      {
      items: int list [@default [1; 2]];
      items_a: int array [@default [|1;2|]];
      name: string [@default "x"]}[@@deriving jsonschema]
    include
      struct
        let record_with_default_with_shadowed_stdlib_jsonschema =
          `Assoc
            [("type", (`String "object"));
            ("properties",
              (`Assoc
                 [("name",
                    ((match string_jsonschema with
                      | `Assoc ppx_fields ->
                          `Assoc (("default", (`String "x")) :: ppx_fields)
                      | ppx_other -> ppx_other)));
                 ("items_a",
                   ((match array_jsonschema int_jsonschema with
                     | `Assoc ppx_fields ->
                         `Assoc
                           (("default",
                              (`List
                                 (Stdlib.Array.to_list
                                    (Stdlib.Array.map
                                       (fun ppx_item -> `Int ppx_item)
                                       [|1;2|]))))
                           :: ppx_fields)
                     | ppx_other -> ppx_other)));
                 ("items",
                   ((match list_jsonschema int_jsonschema with
                     | `Assoc ppx_fields ->
                         `Assoc
                           (("default",
                              (`List
                                 (Stdlib.List.map
                                    (fun ppx_item -> `Int ppx_item) [1; 2])))
                           :: ppx_fields)
                     | ppx_other -> ppx_other)))]));
            ("required", (`List []));
            ("additionalProperties", (`Bool true))][@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    type non_rec_using_wrapper_with_shadowed_stdlib =
      int wrapper_with_shadowed_stdlib[@@deriving jsonschema]
    include
      struct
        let non_rec_using_wrapper_with_shadowed_stdlib_jsonschema =
          Jsonkit_jsonschema_defs.non_recursive
            (wrapper_with_shadowed_stdlib_jsonschema int_jsonschema)[@@warning
                                                                    "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
  end
module Nonrec_type_alias =
  struct
    type foo =
      | A 
      | B [@@deriving jsonschema]
    include
      struct
        let foo_jsonschema =
          `Assoc
            [("anyOf",
               (`List
                  [`Assoc
                     [("type", (`String "array"));
                     ("prefixItems",
                       (`List [`Assoc [("const", (`String "A"))]]));
                     ("unevaluatedItems", (`Bool false));
                     ("minItems", (`Int 1));
                     ("maxItems", (`Int 1))];
                  `Assoc
                    [("type", (`String "array"));
                    ("prefixItems",
                      (`List [`Assoc [("const", (`String "B"))]]));
                    ("unevaluatedItems", (`Bool false));
                    ("minItems", (`Int 1));
                    ("maxItems", (`Int 1))]]))][@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    module X =
      struct
        type nonrec foo = foo[@@deriving jsonschema]
        include
          struct
            let foo_jsonschema =
              Jsonkit_jsonschema_defs.non_recursive foo_jsonschema[@@warning
                                                                    "-32-39"]
          end[@@ocaml.doc "@inline"][@@merlin.hide ]
      end
  end
module Recursive_shapes =
  struct
    type a =
      | A of b 
    and b = int[@@deriving jsonschema]
    include
      struct
        let (a_jsonschema, b_jsonschema) =
          let ppx_defs =
            [("a",
               (`Assoc
                  [("anyOf",
                     (`List
                        [`Assoc
                           [("type", (`String "array"));
                           ("prefixItems",
                             (`List
                                [`Assoc [("const", (`String "A"))];
                                `Assoc [("$ref", (`String "#/$defs/b"))]]));
                           ("unevaluatedItems", (`Bool false));
                           ("minItems", (`Int 2));
                           ("maxItems", (`Int 2))]]))]));
            ("b", int_jsonschema)] in
          let a_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/a"))] in
          let b_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/b"))] in
          (a_jsonschema, b_jsonschema)[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    type t =
      | N 
      | S of t [@@deriving jsonschema]
    include
      struct
        let t_jsonschema =
          let ppx_defs =
            [("t",
               (`Assoc
                  [("anyOf",
                     (`List
                        [`Assoc
                           [("type", (`String "array"));
                           ("prefixItems",
                             (`List [`Assoc [("const", (`String "N"))]]));
                           ("unevaluatedItems", (`Bool false));
                           ("minItems", (`Int 1));
                           ("maxItems", (`Int 1))];
                        `Assoc
                          [("type", (`String "array"));
                          ("prefixItems",
                            (`List
                               [`Assoc [("const", (`String "S"))];
                               `Assoc [("$ref", (`String "#/$defs/t"))]]));
                          ("unevaluatedItems", (`Bool false));
                          ("minItems", (`Int 2));
                          ("maxItems", (`Int 2))]]))]))] in
          let t_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/t"))] in
          t_jsonschema[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    type 'a lst =
      | Nil 
      | Cons of 'a * 'a lst [@@deriving jsonschema]
    include
      struct
        let lst_jsonschema =
          let ppx_defs_lst a =
            [("lst",
               (`Assoc
                  [("anyOf",
                     (`List
                        [`Assoc
                           [("type", (`String "array"));
                           ("prefixItems",
                             (`List [`Assoc [("const", (`String "Nil"))]]));
                           ("unevaluatedItems", (`Bool false));
                           ("minItems", (`Int 1));
                           ("maxItems", (`Int 1))];
                        `Assoc
                          [("type", (`String "array"));
                          ("prefixItems",
                            (`List
                               [`Assoc [("const", (`String "Cons"))];
                               a;
                               `Assoc
                                 [("$ref",
                                    (`String
                                       "#/$defs/\000Cases.Recursive_shapes.lst"))]]));
                          ("unevaluatedItems", (`Bool false));
                          ("minItems", (`Int 3));
                          ("maxItems", (`Int 3))]]))]))] in
          let lst_jsonschema a =
            Jsonkit_jsonschema_defs.member "lst"
              (Jsonkit_jsonschema_defs.recursive_group
                 ~path:"Cases.Recursive_shapes" (ppx_defs_lst a)) in
          lst_jsonschema[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
    type 'a tree =
      | Leaf of 'a 
      | Node of 'a * 'a forest 
    and 'a forest =
      | Empty 
      | Base of 'a tree * 'a forest [@@deriving jsonschema]
    include
      struct
        let (tree_jsonschema, forest_jsonschema) =
          let ppx_defs_tree a =
            [("tree",
               (`Assoc
                  [("anyOf",
                     (`List
                        [`Assoc
                           [("type", (`String "array"));
                           ("prefixItems",
                             (`List [`Assoc [("const", (`String "Leaf"))]; a]));
                           ("unevaluatedItems", (`Bool false));
                           ("minItems", (`Int 2));
                           ("maxItems", (`Int 2))];
                        `Assoc
                          [("type", (`String "array"));
                          ("prefixItems",
                            (`List
                               [`Assoc [("const", (`String "Node"))];
                               a;
                               `Assoc
                                 [("$ref",
                                    (`String
                                       "#/$defs/\000Cases.Recursive_shapes.forest"))]]));
                          ("unevaluatedItems", (`Bool false));
                          ("minItems", (`Int 3));
                          ("maxItems", (`Int 3))]]))]));
            ("forest",
              (`Assoc
                 [("anyOf",
                    (`List
                       [`Assoc
                          [("type", (`String "array"));
                          ("prefixItems",
                            (`List [`Assoc [("const", (`String "Empty"))]]));
                          ("unevaluatedItems", (`Bool false));
                          ("minItems", (`Int 1));
                          ("maxItems", (`Int 1))];
                       `Assoc
                         [("type", (`String "array"));
                         ("prefixItems",
                           (`List
                              [`Assoc [("const", (`String "Base"))];
                              `Assoc
                                [("$ref",
                                   (`String
                                      "#/$defs/\000Cases.Recursive_shapes.tree"))];
                              `Assoc
                                [("$ref",
                                   (`String
                                      "#/$defs/\000Cases.Recursive_shapes.forest"))]]));
                         ("unevaluatedItems", (`Bool false));
                         ("minItems", (`Int 3));
                         ("maxItems", (`Int 3))]]))]))] in
          let tree_jsonschema a =
            Jsonkit_jsonschema_defs.member "tree"
              (Jsonkit_jsonschema_defs.recursive_group
                 ~path:"Cases.Recursive_shapes" (ppx_defs_tree a)) in
          let forest_jsonschema a =
            Jsonkit_jsonschema_defs.member "forest"
              (Jsonkit_jsonschema_defs.recursive_group
                 ~path:"Cases.Recursive_shapes" (ppx_defs_tree a)) in
          (tree_jsonschema, forest_jsonschema)[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
  end
module Same_name_a =
  struct
    type t = {
      next: t option ;
      x: int }[@@deriving jsonschema]
    include
      struct
        let t_jsonschema =
          let ppx_defs =
            [("t",
               (`Assoc
                  [("type", (`String "object"));
                  ("properties",
                    (`Assoc
                       [("x", int_jsonschema);
                       ("next",
                         (option_jsonschema
                            (`Assoc [("$ref", (`String "#/$defs/t"))])))]));
                  ("required", (`List [`String "x"; `String "next"]));
                  ("additionalProperties", (`Bool true))]))] in
          let t_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/t"))] in
          t_jsonschema[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
  end
module Same_name_b =
  struct
    type t = {
      next: t option ;
      y: string }[@@deriving jsonschema]
    include
      struct
        let t_jsonschema =
          let ppx_defs =
            [("t",
               (`Assoc
                  [("type", (`String "object"));
                  ("properties",
                    (`Assoc
                       [("y", string_jsonschema);
                       ("next",
                         (option_jsonschema
                            (`Assoc [("$ref", (`String "#/$defs/t"))])))]));
                  ("required", (`List [`String "y"; `String "next"]));
                  ("additionalProperties", (`Bool true))]))] in
          let t_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/t"))] in
          t_jsonschema[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
  end
type same_name = {
  a: Same_name_a.t ;
  b: Same_name_b.t }[@@deriving jsonschema]
include
  struct
    let same_name_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("b", Same_name_b.t_jsonschema);
                ("a", Same_name_a.t_jsonschema)]));
           ("required", (`List [`String "b"; `String "a"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
module Same_ref_a =
  struct
    type t = {
      foo: t option ;
      u: u }
    and u = {
      x: int }[@@deriving jsonschema]
    include
      struct
        let (t_jsonschema, u_jsonschema) =
          let ppx_defs =
            [("t",
               (`Assoc
                  [("type", (`String "object"));
                  ("properties",
                    (`Assoc
                       [("u", (`Assoc [("$ref", (`String "#/$defs/u"))]));
                       ("foo",
                         (option_jsonschema
                            (`Assoc [("$ref", (`String "#/$defs/t"))])))]));
                  ("required", (`List [`String "u"; `String "foo"]));
                  ("additionalProperties", (`Bool true))]));
            ("u",
              (`Assoc
                 [("type", (`String "object"));
                 ("properties", (`Assoc [("x", int_jsonschema)]));
                 ("required", (`List [`String "x"]));
                 ("additionalProperties", (`Bool true))]))] in
          let t_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/t"))] in
          let u_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/u"))] in
          (t_jsonschema, u_jsonschema)[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
  end
module Same_ref_b =
  struct
    type t = {
      foo: t option ;
      u: u }
    and u = {
      x: string }[@@deriving jsonschema]
    include
      struct
        let (t_jsonschema, u_jsonschema) =
          let ppx_defs =
            [("t",
               (`Assoc
                  [("type", (`String "object"));
                  ("properties",
                    (`Assoc
                       [("u", (`Assoc [("$ref", (`String "#/$defs/u"))]));
                       ("foo",
                         (option_jsonschema
                            (`Assoc [("$ref", (`String "#/$defs/t"))])))]));
                  ("required", (`List [`String "u"; `String "foo"]));
                  ("additionalProperties", (`Bool true))]));
            ("u",
              (`Assoc
                 [("type", (`String "object"));
                 ("properties", (`Assoc [("x", string_jsonschema)]));
                 ("required", (`List [`String "x"]));
                 ("additionalProperties", (`Bool true))]))] in
          let t_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/t"))] in
          let u_jsonschema =
            `Assoc
              [("$defs", (`Assoc ppx_defs)); ("$ref", (`String "#/$defs/u"))] in
          (t_jsonschema, u_jsonschema)[@@warning "-32-39"]
      end[@@ocaml.doc "@inline"][@@merlin.hide ]
  end
type same_ref = {
  a: Same_ref_a.t ;
  b: Same_ref_b.t }[@@deriving jsonschema]
include
  struct
    let same_ref_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("b", Same_ref_b.t_jsonschema);
                ("a", Same_ref_a.t_jsonschema)]));
           ("required", (`List [`String "b"; `String "a"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type described_a = {
  b: described_b option }[@@jsonschema.description "A"]
and described_b = {
  a: described_a option }[@@jsonschema.description "B"][@@deriving
                                                         jsonschema]
include
  struct
    let (described_a_jsonschema, described_b_jsonschema) =
      let ppx_defs =
        [("described_a",
           (`Assoc
              [("description", (`String "A"));
              ("type", (`String "object"));
              ("properties",
                (`Assoc
                   [("b",
                      (option_jsonschema
                         (`Assoc [("$ref", (`String "#/$defs/described_b"))])))]));
              ("required", (`List [`String "b"]));
              ("additionalProperties", (`Bool true))]));
        ("described_b",
          (`Assoc
             [("description", (`String "B"));
             ("type", (`String "object"));
             ("properties",
               (`Assoc
                  [("a",
                     (option_jsonschema
                        (`Assoc [("$ref", (`String "#/$defs/described_a"))])))]));
             ("required", (`List [`String "a"]));
             ("additionalProperties", (`Bool true))]))] in
      let described_a_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/described_a"))] in
      let described_b_jsonschema =
        `Assoc
          [("$defs", (`Assoc ppx_defs));
          ("$ref", (`String "#/$defs/described_b"))] in
      (described_a_jsonschema, described_b_jsonschema)[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type described_pair = {
  x: described_a ;
  y: described_b }[@@deriving jsonschema]
include
  struct
    let described_pair_jsonschema =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("type", (`String "object"));
           ("properties",
             (`Assoc
                [("y", described_b_jsonschema);
                ("x", described_a_jsonschema)]));
           ("required", (`List [`String "y"; `String "x"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'a wrap =
  | Wrap of 'a wrap option 
  | Value of 'a [@@deriving jsonschema]
include
  struct
    let wrap_jsonschema =
      let ppx_defs_wrap a =
        [("wrap",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List
                            [`Assoc [("const", (`String "Wrap"))];
                            option_jsonschema
                              (`Assoc
                                 [("$ref",
                                    (`String "#/$defs/\000Cases.wrap"))])]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List [`Assoc [("const", (`String "Value"))]; a]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]))] in
      let wrap_jsonschema a =
        Jsonkit_jsonschema_defs.member "wrap"
          (Jsonkit_jsonschema_defs.recursive_group ~path:"Cases"
             (ppx_defs_wrap a)) in
      wrap_jsonschema[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type 'a described_box = {
  item: 'a }[@@jsonschema.description "Box"]
and described_tag = string[@@jsonschema.description "Tag"][@@deriving
                                                            jsonschema]
include
  struct
    let described_box_jsonschema a =
      Jsonkit_jsonschema_defs.non_recursive
        (`Assoc
           [("description", (`String "Box"));
           ("type", (`String "object"));
           ("properties", (`Assoc [("item", a)]));
           ("required", (`List [`String "item"]));
           ("additionalProperties", (`Bool true))])[@@warning "-32-39"]
    let described_tag_jsonschema =
      match string_jsonschema with
      | `Assoc ppx_fields ->
          `Assoc (("description", (`String "Tag")) :: ppx_fields)
      | ppx_other -> ppx_other[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
type wrapped_a =
  | Wrapped_a of wrapped_b 
  | Wrapped_stop 
and wrapped_b =
  | Wrapped_b of wrapped_a wrap [@@deriving jsonschema]
include
  struct
    let (wrapped_a_jsonschema, wrapped_b_jsonschema) =
      let ppx_defs_wrapped_a =
        [("wrapped_a",
           (`Assoc
              [("anyOf",
                 (`List
                    [`Assoc
                       [("type", (`String "array"));
                       ("prefixItems",
                         (`List
                            [`Assoc [("const", (`String "Wrapped_a"))];
                            `Assoc
                              [("$ref",
                                 (`String "#/$defs/\000Cases.wrapped_b"))]]));
                       ("unevaluatedItems", (`Bool false));
                       ("minItems", (`Int 2));
                       ("maxItems", (`Int 2))];
                    `Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List [`Assoc [("const", (`String "Wrapped_stop"))]]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 1));
                      ("maxItems", (`Int 1))]]))]));
        ("wrapped_b",
          (`Assoc
             [("anyOf",
                (`List
                   [`Assoc
                      [("type", (`String "array"));
                      ("prefixItems",
                        (`List
                           [`Assoc [("const", (`String "Wrapped_b"))];
                           wrap_jsonschema
                             (`Assoc
                                [("$ref",
                                   (`String "#/$defs/\000Cases.wrapped_a"))])]));
                      ("unevaluatedItems", (`Bool false));
                      ("minItems", (`Int 2));
                      ("maxItems", (`Int 2))]]))]))] in
      let ppx_group =
        Jsonkit_jsonschema_defs.recursive_group ~path:"Cases"
          ppx_defs_wrapped_a in
      let wrapped_a_jsonschema =
        Jsonkit_jsonschema_defs.member "wrapped_a" ppx_group in
      let wrapped_b_jsonschema =
        Jsonkit_jsonschema_defs.member "wrapped_b" ppx_group in
      (wrapped_a_jsonschema, wrapped_b_jsonschema)[@@warning "-32-39"]
  end[@@ocaml.doc "@inline"][@@merlin.hide ]
module Hoist =
  struct
    let assoc fields : Jsonkit.Jsonschema.t= `Assoc fields
    let string value : Jsonkit.Jsonschema.t= `String value
    let ref_ name = assoc [("$ref", (string ("#/$defs/" ^ name)))]
    let const value = assoc [("const", (string value))]
    let nested_scope =
      Jsonkit.Jsonschema.make
        (assoc
           [("$defs",
              (assoc
                 [("outer",
                    (assoc
                       [("$defs", (assoc [("t", (const "inner"))]));
                       ("$ref", (string "#/$defs/t"))]));
                 ("t", (const "outer"))]));
           ("$ref", (string "#/$defs/t"))])
    let mixed_collision =
      Jsonkit.Jsonschema.make
        ~definitions:[("same", (const "same"));
                     ("different", (const "existing"))]
        (assoc
           [("$defs",
              (assoc [("same", (const "same")); ("different", (const "new"))]));
           ("same", (ref_ "same"));
           ("different", (ref_ "different"))])
    let user_resource =
      Jsonkit.Jsonschema.make
        (assoc
           [("resource",
              (assoc
                 [("$id", (string "https://example.test/resource"));
                 ("$defs", (assoc [("t", (const "local"))]));
                 ("$ref", (string "#/$defs/t"))]))])
  end
