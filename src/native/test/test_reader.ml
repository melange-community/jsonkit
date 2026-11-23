open Jsonkit.Primitives
module R = Jsonkit.Reader

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
}
[@@deriving json]

let color_of_json_lexbuf p lb =
  R.variant
    (fun tag p lb ->
      match tag with
      | "Red" -> Red
      | "Blue" ->
          R.array_next p lb;
          Blue (R.int p lb)
      | tag -> Jsonkit.of_json_msg_unexpected_variant tag)
    p lb

let point_of_json_lexbuf p lb =
  R.array_start p lb;
  let x = R.float p lb in
  R.array_next p lb;
  let y = R.float p lb in
  R.array_end p lb;
  x, y

let address_of_json_lexbuf p lb =
  let street = ref "" and zip = ref None and seen = ref 0 in
  R.object_fields
    (fun key p lb ->
      match key with
      | "street" ->
          street := R.string p lb;
          seen := !seen lor 1
      | "zip" ->
          zip := R.option R.string p lb;
          seen := !seen lor 2
      | _ -> R.skip p lb)
    p lb;
  if !seen <> 3 then R.missing_field "address" "street";
  { street = !street; zip = !zip }

let item_of_json_lexbuf p lb =
  let id = ref 0
  and name = ref ""
  and big = ref 0L
  and ratio = ref 0.
  and live = ref false
  and nothing = ref ()
  and color = ref Red
  and at = ref (0., 0.)
  and tags = ref []
  and scores = ref [||]
  and address = ref { street = ""; zip = None }
  and outcome = ref (Ok 0)
  and note = ref None
  and seen = ref 0 in
  R.object_fields
    (fun key p lb ->
      match key with
      | "id" ->
          id := R.int p lb;
          seen := !seen lor 1
      | "name" ->
          name := R.string p lb;
          seen := !seen lor 2
      | "big" ->
          big := R.int64 p lb;
          seen := !seen lor 4
      | "ratio" ->
          ratio := R.float p lb;
          seen := !seen lor 8
      | "live" ->
          live := R.bool p lb;
          seen := !seen lor 16
      | "nothing" ->
          nothing := R.unit p lb;
          seen := !seen lor 32
      | "color" ->
          color := color_of_json_lexbuf p lb;
          seen := !seen lor 64
      | "at" ->
          at := point_of_json_lexbuf p lb;
          seen := !seen lor 128
      | "tags" ->
          tags := R.list R.string p lb;
          seen := !seen lor 256
      | "scores" ->
          scores := R.array R.int p lb;
          seen := !seen lor 512
      | "address" ->
          address := address_of_json_lexbuf p lb;
          seen := !seen lor 1024
      | "outcome" ->
          outcome := R.result R.int R.string p lb;
          seen := !seen lor 2048
      | "note" ->
          note := R.option R.string p lb;
          seen := !seen lor 4096
      | _ -> R.skip p lb)
    p lb;
  if !seen <> 8191 then R.missing_field "item" "one of its fields";
  {
    id = !id;
    name = !name;
    big = !big;
    ratio = !ratio;
    live = !live;
    nothing = !nothing;
    color = !color;
    at = !at;
    tags = !tags;
    scores = !scores;
    address = !address;
    outcome = !outcome;
    note = !note;
  }

let failures = ref 0

let fail what =
  incr failures;
  print_endline ("FAIL: " ^ what)

let check what cond = if not cond then fail what

let outcome f =
  match f () with
  | v -> Ok v
  | exception e -> Error (Printexc.to_string e)

let check_same what s =
  let slow = outcome (fun () -> item_of_json (Jsonkit.of_string s)) in
  let fast =
    outcome (fun () ->
        R.of_string ~of_json:item_of_json item_of_json_lexbuf s)
  in
  match slow, fast with
  | Ok a, Ok b when a = b -> ()
  | Error a, Error b when a = b -> ()
  | Ok _, Error e -> fail (what ^ ": reader failed with " ^ e)
  | Error e, Ok _ ->
      fail (what ^ ": reader accepted what of_json rejected (" ^ e ^ ")")
  | Ok _, Ok _ -> fail (what ^ ": readers disagree on the value")
  | Error a, Error b ->
      fail (what ^ ": error messages differ: " ^ a ^ " / " ^ b)

let item =
  {
    id = 42;
    name = "S\195\163o \"Paulo\"";
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
  }

let () =
  let compact = Jsonkit.to_string (item_to_json item) in
  check "round trip" (R.run item_of_json_lexbuf compact = item);
  check "run on pretty printed"
    (R.run item_of_json_lexbuf
       (Yojson.Basic.pretty_to_string (item_to_json item))
    = item);
  check "float written as int" (R.run R.float "3" = 3.);
  check "nested option" (R.run (R.option (R.option R.int)) "null" = None);
  check "empty object"
    (R.run (R.object_fields (fun _ _ _ -> ())) "{}" = ());
  check "empty list" (R.run (R.list R.int) "[]" = []);
  check "escapes"
    (R.run R.string {|"line1\nline2é"|} = "line1\nline2\195\169");
  check_same "compact" compact;
  check_same "pretty" (Yojson.Basic.pretty_to_string (item_to_json item));
  check_same "fields out of order"
    (String.concat ""
       [
         {|{"note":null,"outcome":["Error","nope"],|};
         {|"address":{"zip":"1000-001","street":"1 Main Street"},|};
         {|"scores":[1,2,3],"tags":["a","b"],"at":[38.7223,-9.1393],|};
         {|"color":["Blue",7],"nothing":null,"live":true,"ratio":0.125,|};
         {|"big":"9223372036854775807","name":"x","id":42}|};
       ]);
  check_same "extra fields"
    (String.concat ""
       [
         {|{"extra":{"a":[1,2,{"b":null}]},"id":42,"name":"x",|};
         {|"big":"1","ratio":0.5,"live":false,"nothing":null,|};
         {|"color":["Red"],"at":[1.0,2.0],"tags":[],"scores":[],|};
         {|"address":{"street":"s","zip":null},"outcome":["Ok",1],|};
         {|"note":"hi","trailing":"ignored"}|};
       ]);
  check_same "missing field" {|{"id":42}|};
  check_same "wrong type"
    (String.concat "" [ {|{"id":"42","name":"x",|}; {|"big":"1"}|} ]);
  check_same "unknown variant"
    (String.concat ""
       [
         {|{"id":1,"name":"x","big":"1","ratio":0.5,"live":false,|};
         {|"nothing":null,"color":["Green"],"at":[1.0,2.0],"tags":[],|};
         {|"scores":[],"address":{"street":"s","zip":null},|};
         {|"outcome":["Ok",1],"note":null}|};
       ]);
  check_same "malformed" {|{"id":42,|};
  check_same "trailing garbage" (compact ^ " x");
  check_same "not an object" {|[1,2,3]|};
  (match R.run item_of_json_lexbuf (compact ^ " x") with
  | _ -> fail "run accepted trailing garbage"
  | exception Jsonkit.Of_string_error _ -> ());
  if !failures = 0 then print_endline "jsonkit reader: ok"
  else (
    Printf.printf "jsonkit reader: %d failure(s)\n" !failures;
    exit 1)
