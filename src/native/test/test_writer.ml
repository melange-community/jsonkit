open Jsonkit.Primitives
module W = Jsonkit.Writer

let equal_int = Int.equal

type color = Red | Blue of int [@@deriving json]
type point = float * float [@@deriving json]
type address = { street : string; zip : string option } [@@deriving json]

type item = {
  id : int;
  name : string;
  big : int64;
  ratio : float;
  live : bool;
  nothing : unit;
  color : color;
  at : point;
  tags : string list;
  scores : int array;
  address : address;
  outcome : (int, string) result;
  note : string option;
  absent : string option; [@json.option]
  dropped : string option; [@json.option] [@json.drop_default]
  counted : int; [@json.default 0] [@json.drop_default]
}
[@@deriving json]

let color_to_json_buffer v buffer =
  let b = buffer in
  match v with
  | Red -> Buffer.add_string b {|["Red"]|}
  | Blue v ->
      Buffer.add_string b {|["Blue",|};
      W.int v b;
      Buffer.add_char b ']'

let point_to_json_buffer (x, y) b =
  Buffer.add_char b '[';
  W.float x b;
  Buffer.add_char b ',';
  W.float y b;
  Buffer.add_char b ']'

let address_to_json_buffer (v : address) b =
  W.obj b (fun o ->
      W.string v.street (W.key o {|"street":|});
      W.option W.string v.zip (W.key o {|"zip":|}))

let item_to_json_buffer (v : item) b =
  W.obj b (fun o ->
      W.int v.id (W.key o {|"id":|});
      W.string v.name (W.key o {|"name":|});
      W.int64 v.big (W.key o {|"big":|});
      W.float v.ratio (W.key o {|"ratio":|});
      W.bool v.live (W.key o {|"live":|});
      W.unit v.nothing (W.key o {|"nothing":|});
      color_to_json_buffer v.color (W.key o {|"color":|});
      point_to_json_buffer v.at (W.key o {|"at":|});
      W.list W.string v.tags (W.key o {|"tags":|});
      W.array W.int v.scores (W.key o {|"scores":|});
      address_to_json_buffer v.address (W.key o {|"address":|});
      W.result W.int W.string v.outcome (W.key o {|"outcome":|});
      W.option W.string v.note (W.key o {|"note":|});
      W.option W.string v.absent (W.key o {|"absent":|});
      (match v.dropped with
      | None -> ()
      | Some s -> W.string s (W.key o {|"dropped":|}));
      if v.counted <> 0 then W.int v.counted (W.key o {|"counted":|}))

let failures = ref 0

let fail what expected actual =
  incr failures;
  Printf.printf "FAIL %s\n  tree:   %s\n  writer: %s\n" what expected
    actual

let check_bytes what to_json writer v =
  let expected = Jsonkit.to_string (to_json v) in
  let actual = W.to_string writer v in
  if expected <> actual then fail what expected actual

let base =
  {
    id = 42;
    name = "S\195\163o \"Paulo\"\n\tx\000y";
    big = 9223372036854775807L;
    ratio = 0.125;
    live = true;
    nothing = ();
    color = Blue 7;
    at = 38.7223, -9.1393;
    tags = [ "a"; "b" ];
    scores = [| 1; 2; 3 |];
    address = { street = "1 Main Street"; zip = Some "1000-001" };
    outcome = Error "nope";
    note = None;
    absent = None;
    dropped = None;
    counted = 0;
  }

let () =
  check_bytes "full record" item_to_json item_to_json_buffer base;
  check_bytes "dropped fields present" item_to_json item_to_json_buffer
    { base with absent = Some "a"; dropped = Some "b"; counted = 3 };
  check_bytes "dropped option only" item_to_json item_to_json_buffer
    { base with dropped = Some "b" };
  check_bytes "dropped default only" item_to_json item_to_json_buffer
    { base with counted = 7 };
  check_bytes "empty collections" item_to_json item_to_json_buffer
    {
      base with
      tags = [];
      scores = [||];
      color = Red;
      outcome = Ok 0;
      note = Some "";
      address = { street = ""; zip = None };
    };
  List.iter
    (fun (what, f) ->
      check_bytes ("float " ^ what) float_to_json W.float f)
    [
      "zero", 0.;
      "negative zero", -0.;
      "integral", 1.;
      "large integral", 1e22;
      "tiny", 1e-310;
      "pi", 3.141592653589793;
      "max", max_float;
      "nan", Float.nan;
      "infinity", Float.infinity;
      "neg infinity", Float.neg_infinity;
    ];
  List.iter
    (fun (what, s) ->
      check_bytes ("string " ^ what) string_to_json W.string s)
    [
      "empty", "";
      "quotes", {|a"b\c|};
      "control", "\000\001\031\127";
      "newlines", "a\nb\r\tc";
      "utf8", "S\195\163o Paulo \226\130\172";
      "lone high byte", "\xff\xfe";
    ];
  List.iter
    (fun (what, v) ->
      check_bytes ("int64 " ^ what) int64_to_json W.int64 v)
    [ "zero", 0L; "min", Int64.min_int; "max", Int64.max_int ];
  check_bytes "nested option none"
    (option_to_json (option_to_json int_to_json))
    (W.option (W.option W.int))
    None;
  check_bytes "nested option some none"
    (option_to_json (option_to_json int_to_json))
    (W.option (W.option W.int))
    (Some None);
  check_bytes "json passthrough"
    (fun j -> j)
    W.json
    (Jsonkit.of_string {|{"a":[1,2.5,null,true,"x"],"b":{}}|});
  if !failures = 0 then print_endline "jsonkit writer: ok"
  else (
    Printf.printf "jsonkit writer: %d failure(s)\n" !failures;
    exit 1)
