open Jsonkit.Primitives

let equal_int = Int.equal

type simple = { a : int; b : string } [@@deriving json]

type keyed = {
  normal : int;
  spaced : int; [@json.key "with space"]
  quoted : int; [@json.key "qu\"ote\\d"]
  unicode : int; [@json.key "ac\195\169nt"]
}
[@@deriving json]

type drops = {
  kept : int;
  maybe : string option; [@json.option] [@json.drop_default]
  counted : int; [@json.default 0] [@json.drop_default]
  labelled : string;
      [@json.default "none"] [@json.drop_default_if_json_equal]
  plain : string option; [@json.option]
}
[@@deriving json]

type shape =
  | Dot
  | Line of int * int
  | Named of string [@json.name "named_shape"]
  | Boxed of { width : float; height : float }
[@@deriving json]

type compact = Solo | Pair of int * string
[@@deriving json] [@@json.compact_variants]

type caught =
  | Known
  | Known_of_int of int
  | Other of Jsonkit.unknown_variant_case [@json.catch_all]
[@@deriving json] [@@json.compact_variants]

type anything = Any of Yojson.Basic.t [@allow_any] | Plain
[@@deriving json]

type poly = [ `A | `B of int ] [@@deriving json]
type poly2 = [ `C of int * string ] [@@deriving json]
type poly3 = [ poly | poly2 ] [@@deriving json]

type poly_caught =
  [ `A | `Other of Jsonkit.unknown_variant_case [@json.catch_all] ]
[@@deriving json]

type pair = int * string [@@deriving json]
type nested = (int * string) list option [@@deriving json]
type tree = Leaf of int | Node of tree * tree [@@deriving json]
type 'a box = { value : 'a; tag : string } [@@deriving json]

type scalars = {
  i : int;
  big : int64;
  f : float;
  bool_ : bool;
  nothing : unit;
  items : string list;
  slots : int array;
  outcome : (int, string) result;
  maybe : float option;
}
[@@deriving json]

let failures = ref 0

let check what to_json writer v =
  let expected = Jsonkit.to_string (to_json v) in
  let actual = Jsonkit.Writer.to_string writer v in
  if expected <> actual then (
    incr failures;
    Printf.printf "FAIL %s\n  to_json: %s\n  writer:  %s\n" what expected
      actual)

let () =
  check "simple" simple_to_json simple_to_json_buffer { a = 1; b = "x" };
  check "keyed" keyed_to_json keyed_to_json_buffer
    { normal = 1; spaced = 2; quoted = 3; unicode = 4 };
  check "drops all absent" drops_to_json drops_to_json_buffer
    {
      kept = 1;
      maybe = None;
      counted = 0;
      labelled = "none";
      plain = None;
    };
  check "drops all present" drops_to_json drops_to_json_buffer
    {
      kept = 1;
      maybe = Some "here";
      counted = 7;
      labelled = "other";
      plain = Some "p";
    };
  List.iter
    (fun (what, v) ->
      check ("shape " ^ what) shape_to_json shape_to_json_buffer v)
    [
      "dot", Dot;
      "line", Line (1, 2);
      "named", Named "n";
      "boxed", Boxed { width = 1.5; height = 2. };
    ];
  List.iter
    (fun (what, v) ->
      check ("compact " ^ what) compact_to_json compact_to_json_buffer v)
    [ "solo", Solo; "pair", Pair (1, "x") ];
  List.iter
    (fun (what, v) ->
      check ("caught " ^ what) caught_to_json caught_to_json_buffer v)
    [
      "known", Known;
      "known_of_int", Known_of_int 42;
      "bare", Other { Jsonkit.tag = "Unknown"; payload = None };
      "empty", Other { Jsonkit.tag = "Unknown"; payload = Some [] };
      ( "payload",
        Other
          {
            Jsonkit.tag = "Unknown";
            payload = Some [ int_to_json 1; string_to_json "x" ];
          } );
    ];
  List.iter
    (fun (what, v) ->
      check ("anything " ^ what) anything_to_json anything_to_json_buffer
        v)
    [
      "plain", Plain;
      "any", Any (Jsonkit.of_string {|{"a":[1,null,true]}|});
      "any string", Any (Jsonkit.of_string {|"text"|});
    ];
  List.iter
    (fun (what, v) ->
      check ("poly " ^ what) poly_to_json poly_to_json_buffer v)
    [ "a", `A; "b", `B 3 ];
  List.iter
    (fun (what, v) ->
      check ("poly3 " ^ what) poly3_to_json poly3_to_json_buffer v)
    [ "inherited a", `A; "inherited b", `B 3; "own", `C (1, "x") ];
  List.iter
    (fun (what, v) ->
      check ("poly_caught " ^ what) poly_caught_to_json
        poly_caught_to_json_buffer v)
    [
      "known", `A;
      "unknown", `Other { Jsonkit.tag = "Zzz"; payload = Some [] };
      ( "unknown payload",
        `Other { Jsonkit.tag = "Zzz"; payload = Some [ int_to_json 1 ] } );
    ];
  check "pair" pair_to_json pair_to_json_buffer (1, "x");
  check "nested none" nested_to_json nested_to_json_buffer None;
  check "nested some" nested_to_json nested_to_json_buffer
    (Some [ 1, "a"; 2, "b" ]);
  check "nested empty" nested_to_json nested_to_json_buffer (Some []);
  check "tree" tree_to_json tree_to_json_buffer
    (Node (Leaf 1, Node (Leaf 2, Leaf 3)));
  check "box int"
    (box_to_json int_to_json)
    (box_to_json_buffer int_to_json_buffer)
    { value = 1; tag = "t" };
  check "box list"
    (box_to_json (list_to_json string_to_json))
    (box_to_json_buffer (list_to_json_buffer string_to_json_buffer))
    { value = [ "a"; "b" ]; tag = "t" };
  check "scalars" scalars_to_json scalars_to_json_buffer
    {
      i = -3;
      big = Int64.min_int;
      f = 0.1;
      bool_ = false;
      nothing = ();
      items = [];
      slots = [| 1 |];
      outcome = Error "e";
      maybe = Some Float.infinity;
    };
  check "scalars 2" scalars_to_json scalars_to_json_buffer
    {
      i = 0;
      big = 0L;
      f = -0.;
      bool_ = true;
      nothing = ();
      items = [ "a" ];
      slots = [||];
      outcome = Ok 1;
      maybe = None;
    };
  if !failures = 0 then print_endline "jsonkit derived writer: ok"
  else (
    Printf.printf "jsonkit derived writer: %d failure(s)\n" !failures;
    exit 1)
