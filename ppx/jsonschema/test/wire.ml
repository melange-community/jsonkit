(* Wire test: for types that derive BOTH [to_json] and [jsonschema], check that
   the JSON produced by jsonkit's encoder actually validates against the
   generated JSON Schema.

   The two derivers share jsonkit's attributes ([@key], [@option],
   [@default], [@name], [@@compact_variants], ...), so the schema is supposed to
   describe exactly the wire shape the encoder emits. This test enforces that
   contract by round-tripping sample values through [_to_json] and validating
   the result against [_jsonschema] with an external Draft 2020-12 validator
   ([check-jsonschema]). *)

open Ppx_deriving_jsonschema_runtime.Primitives.Jsonkit
open Jsonkit.Primitives

type json = Yojson.Basic.t

let schema_of ?definitions (s : Ppx_deriving_jsonschema_runtime.t) : json
    =
  (Ppx_deriving_jsonschema_runtime.json_schema ?definitions s :> json)

type case = { name : string; schema : json; instances : json list }

let case name schema instances = { name; schema; instances }

type simple_record = { name : string; age : int; email : string option }
[@@deriving to_json, jsonschema]

let simple_record =
  case "simple_record"
    (schema_of simple_record_jsonschema)
    [
      simple_record_to_json
        { name = "Ada"; age = 36; email = Some "ada@x.dev" };
      simple_record_to_json { name = "Bob"; age = 0; email = None };
    ]

type defaults_record = {
  required_value : int;
  option_value : string option; [@option]
  default_value : string; [@default "-"]
}
[@@deriving to_json, jsonschema]

let defaults_record =
  case "defaults_record"
    (schema_of defaults_record_jsonschema)
    [
      defaults_record_to_json
        {
          required_value = 1;
          option_value = Some "hi";
          default_value = "custom";
        };
      defaults_record_to_json
        { required_value = 2; option_value = None; default_value = "-" };
    ]

type keyed_record = { from : int; to_ : int [@key "to"] }
[@@deriving to_json, jsonschema]

let keyed_record =
  case "keyed_record"
    (schema_of keyed_record_jsonschema)
    [ keyed_record_to_json { from = 0; to_ = 100 } ]

type kind = Success | Error | Skipped [@name "skipped"]
[@@deriving to_json, jsonschema]

let kind =
  case "kind"
    (schema_of kind_jsonschema)
    [ kind_to_json Success; kind_to_json Error; kind_to_json Skipped ]

type payload_variant =
  | Nullary
  | Single of int
  | Pair of int * string
  | Inline of { label : string }
[@@deriving to_json, jsonschema]

let payload_variant =
  case "payload_variant"
    (schema_of payload_variant_jsonschema)
    [
      payload_variant_to_json Nullary;
      payload_variant_to_json (Single 7);
      payload_variant_to_json (Pair (1, "x"));
      payload_variant_to_json (Inline { label = "l" });
    ]

type compact_variant = A | B | C of int
[@@deriving to_json, jsonschema] [@@compact_variants]

let compact_variant =
  case "compact_variant"
    (schema_of compact_variant_jsonschema)
    [
      compact_variant_to_json A;
      compact_variant_to_json B;
      compact_variant_to_json (C 3);
    ]

type poly_variant = [ `Aaa | `Bbb of int ]
[@@deriving to_json, jsonschema]

let poly_variant =
  case "poly_variant"
    (schema_of poly_variant_jsonschema)
    [ poly_variant_to_json `Aaa; poly_variant_to_json (`Bbb 9) ]

type pair = int * string [@@deriving to_json, jsonschema]

let pair =
  case "pair" (schema_of pair_jsonschema) [ pair_to_json (1, "one") ]

type address = { street : string; city : string }
[@@deriving to_json, jsonschema]

type nested = { who : simple_record; where : address }
[@@deriving to_json, jsonschema]

let nested =
  case "nested"
    (schema_of nested_jsonschema)
    [
      nested_to_json
        {
          who = { name = "Ada"; age = 36; email = None };
          where = { street = "1 Main"; city = "Town" };
        };
    ]

type tree = Leaf | Node of { value : int; left : tree; right : tree }
[@@deriving to_json, jsonschema]

let tree =
  case "tree"
    (schema_of tree_jsonschema)
    [
      tree_to_json Leaf;
      tree_to_json
        (Node
           {
             value = 1;
             left = Leaf;
             right = Node { value = 2; left = Leaf; right = Leaf };
           });
    ]

type containers = { numbers : int list; flags : bool array }
[@@deriving to_json, jsonschema]

let containers =
  case "containers"
    (schema_of containers_jsonschema)
    [
      containers_to_json
        { numbers = [ 1; 2; 3 ]; flags = [| true; false |] };
    ]

type primitives = {
  ratio : float;
  active : bool;
  big : int64;
  nothing : unit;
}
[@@deriving to_json, jsonschema]

let primitives =
  case "primitives"
    (schema_of primitives_jsonschema)
    [
      primitives_to_json
        { ratio = 1.5; active = true; big = 9_000_000_000L; nothing = () };
    ]

type outcome = (int, string) result [@@deriving to_json, jsonschema]

let outcome =
  case "outcome"
    (schema_of outcome_jsonschema)
    [ outcome_to_json (Ok 1); outcome_to_json (Error "nope") ]

type optionals = {
  maybe_list : int list option;
  maybe_pair : (int * string) option;
}
[@@deriving to_json, jsonschema]

let optionals =
  case "optionals"
    (schema_of optionals_jsonschema)
    [
      optionals_to_json
        { maybe_list = Some [ 1; 2 ]; maybe_pair = Some (3, "x") };
      optionals_to_json { maybe_list = None; maybe_pair = None };
    ]

type matrix = int list list [@@deriving to_json, jsonschema]

let matrix =
  case "matrix"
    (schema_of matrix_jsonschema)
    [ matrix_to_json [ [ 1; 2 ]; []; [ 3 ] ] ]

type labeled = (int * string) list [@@deriving to_json, jsonschema]

let labeled =
  case "labeled"
    (schema_of labeled_jsonschema)
    [ labeled_to_json [ 1, "a"; 2, "b" ] ]

type person = { name : string; age : int }
[@@deriving to_json, jsonschema]

type roster = person array [@@deriving to_json, jsonschema]

let roster =
  case "roster"
    (schema_of roster_jsonschema)
    [
      roster_to_json
        [| { name = "Ada"; age = 36 }; { name = "Bob"; age = 1 } |];
    ]

type numbers = int list [@@deriving to_json, jsonschema]

type player_scores = {
  player : string;
  scores : numbers; [@ref "numbers"] [@key "scores_ref"]
}
[@@deriving to_json, jsonschema]

let player_scores =
  case "player_scores"
    (schema_of
       ~definitions:[ "numbers", numbers_jsonschema ]
       player_scores_jsonschema)
    [ player_scores_to_json { player = "Ada"; scores = [ 10; 20; 30 ] } ]

type addr = { street : string; city : string }
[@@deriving to_json, jsonschema]

type contact = {
  home_address : addr; [@ref "shared_address"]
  work_address : addr; [@ref "shared_address"]
}
[@@deriving to_json, jsonschema]

let contact =
  case "contact"
    (schema_of
       ~definitions:[ "shared_address", addr_jsonschema ]
       contact_jsonschema)
    [
      contact_to_json
        {
          home_address = { street = "1 Main"; city = "Town" };
          work_address = { street = "2 Side"; city = "City" };
        };
    ]

type foo = { bar : bar option }
and bar = { foo : foo option } [@@deriving to_json, jsonschema]

let foo =
  case "foo"
    (schema_of foo_jsonschema)
    [
      foo_to_json { bar = None };
      foo_to_json { bar = Some { foo = Some { bar = None } } };
    ]

type recursive_tuple =
  | Leaf' of int
  | Branch of (recursive_tuple * recursive_tuple)
[@@deriving to_json, jsonschema]

let recursive_tuple =
  case "recursive_tuple"
    (schema_of recursive_tuple_jsonschema)
    [
      recursive_tuple_to_json (Leaf' 1);
      recursive_tuple_to_json
        (Branch (Leaf' 1, Branch (Leaf' 2, Leaf' 3)));
    ]

(* Polymorphic variants with payloads, tuple payloads, and inheritance. *)
type poly_payload = [ `Aaa of int | `Bbb | `Ccc of string * bool ]
[@@deriving to_json, jsonschema]

let poly_payload =
  case "poly_payload"
    (schema_of poly_payload_jsonschema)
    [
      poly_payload_to_json (`Aaa 1);
      poly_payload_to_json `Bbb;
      poly_payload_to_json (`Ccc ("x", true));
    ]

type poly_base = [ `Aaa | `Bbb ] [@@deriving to_json, jsonschema]

type poly_inherit = [ `New_one | `Second_one of int | poly_base ]
[@@deriving to_json, jsonschema]

let poly_inherit =
  case "poly_inherit"
    (schema_of poly_inherit_jsonschema)
    [
      poly_inherit_to_json `New_one;
      poly_inherit_to_json (`Second_one 2);
      poly_inherit_to_json `Aaa;
      poly_inherit_to_json `Bbb;
    ]

type ('a, 'b) either = Left of 'a | Right of 'b
[@@deriving to_json, jsonschema]

let either =
  case "either"
    (schema_of (either_jsonschema int_jsonschema string_jsonschema))
    [
      either_to_json int_to_json string_to_json (Left 1);
      either_to_json int_to_json string_to_json (Right "r");
    ]

type 'url link = { title : string option; url : 'url }
[@@deriving to_json, jsonschema]

let link =
  case "link"
    (schema_of (link_jsonschema string_jsonschema))
    [
      link_to_json string_to_json { title = Some "t"; url = "http://x" };
      link_to_json string_to_json { title = None; url = "http://y" };
    ]

type bounded = {
  score : int; [@jsonschema.minimum 0] [@jsonschema.maximum 100]
  fraction : float; [@jsonschema.minimum 0.0] [@jsonschema.maximum 1.0]
}
[@@deriving to_json, jsonschema]

let bounded =
  case "bounded"
    (schema_of bounded_jsonschema)
    [
      bounded_to_json { score = 0; fraction = 0.0 };
      bounded_to_json { score = 100; fraction = 1.0 };
      bounded_to_json { score = 50; fraction = 0.5 };
    ]

type timestamped = { at : string [@jsonschema.format "date-time"] }
[@@deriving to_json, jsonschema]

let timestamped =
  case "timestamped"
    (schema_of timestamped_jsonschema)
    [ timestamped_to_json { at = "2020-01-02T03:04:05Z" } ]

type annotated = {
  note : string option; [@jsonschema.option]
  weight : int; [@jsonschema.default 1]
}
[@@deriving to_json, jsonschema]

let annotated =
  case "annotated"
    (schema_of annotated_jsonschema)
    [
      annotated_to_json { note = Some "hi"; weight = 5 };
      annotated_to_json { note = None; weight = 1 };
    ]

type named_variant =
  | Typ [@name "type"]
  | Klass of string [@name "class"]
[@@deriving to_json, jsonschema]

let named_variant =
  case "named_variant"
    (schema_of named_variant_jsonschema)
    [ named_variant_to_json Typ; named_variant_to_json (Klass "k") ]

type named_poly = [ `Aaa | `Ccc of int [@name "ccc"] ]
[@@deriving to_json, jsonschema]

let named_poly =
  case "named_poly"
    (schema_of named_poly_jsonschema)
    [ named_poly_to_json `Aaa; named_poly_to_json (`Ccc 3) ]

type key_opt = { opt : int option [@key "opt_int"] [@option] }
[@@deriving to_json, jsonschema]

let key_opt =
  case "key_opt"
    (schema_of key_opt_jsonschema)
    [ key_opt_to_json { opt = Some 5 }; key_opt_to_json { opt = None } ]

let cases : case list =
  [
    simple_record;
    defaults_record;
    keyed_record;
    kind;
    payload_variant;
    compact_variant;
    poly_variant;
    pair;
    nested;
    tree;
    containers;
    primitives;
    outcome;
    optionals;
    matrix;
    labeled;
    roster;
    player_scores;
    contact;
    foo;
    recursive_tuple;
    poly_payload;
    poly_inherit;
    either;
    link;
    bounded;
    timestamped;
    annotated;
    named_variant;
    named_poly;
    key_opt;
  ]

let write_file path content =
  let oc = open_out path in
  output_string oc content;
  close_out oc

let read_all ic =
  let buf = Buffer.create 256 in
  (try
     while true do
       Buffer.add_channel buf ic 1
     done
   with End_of_file -> ());
  Buffer.contents buf

let validate ~schema_file ~instance_file =
  let cmd =
    Filename.quote_command "check-jsonschema"
      [ "--schemafile"; schema_file; instance_file ]
  in
  let ic = Unix.open_process_in (cmd ^ " 2>&1") in
  let output = read_all ic in
  match Unix.close_process_in ic with
  | Unix.WEXITED 0 -> Ok ()
  | Unix.WEXITED 127 ->
      Error
        "check-jsonschema not found on PATH (install it to run this test)"
  | _ ->
      let cleaned =
        String.split_on_char '\n' output
        |> List.map (fun line ->
            match String.index_opt line ':' with
            (* remove the file prefix from the error message for a clear output *)
            | Some i when String.length line > i + 1 && line.[i + 1] = ':'
              ->
                ""
            | _ -> line)
        |> String.concat "\n"
      in
      Error (String.trim cleaned)

let () =
  let schema_file = "wire_schema.json" in
  let instance_file = "wire_instance.json" in
  let failures = ref 0 in
  List.iter
    (fun { name; schema; instances } ->
      write_file schema_file (Yojson.Basic.to_string schema);
      let total = List.length instances in
      let ok = ref 0 in
      List.iteri
        (fun i instance ->
          write_file instance_file (Yojson.Basic.to_string instance);
          match validate ~schema_file ~instance_file with
          | Ok () -> incr ok
          | Error msg ->
              incr failures;
              Printf.printf "%s: %s.[%d] is INVALID\nValue: %s\n%s\n" name
                name i
                (Yojson.Basic.to_string instance)
                msg)
        instances;
      if !ok = total then Printf.printf "%s: %d/%d valid\n" name !ok total)
    cases;
  (try Sys.remove schema_file with Sys_error _ -> ());
  (try Sys.remove instance_file with Sys_error _ -> ());
  if !failures > 0 then exit 1
