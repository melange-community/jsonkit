open Jsonkit.Primitives

external same_value : 'a -> 'a -> bool = "is" [@@mel.scope "Object"]

let print fmt = Printf.ksprintf print_endline fmt
let backslash = String.make 1 (Char.chr 92)

let visible input =
  String.concat ""
    (List.map
       (fun c ->
         if Char.code c < 0x20 then Printf.sprintf "<%02x>" (Char.code c)
         else String.make 1 c)
       (List.of_seq (String.to_seq input)))

type 'a outcome = Decoded of 'a | Failed of string

let outcome decode =
  match decode () with
  | value -> Decoded value
  | exception Jsonkit.Of_json_error error ->
      Failed (Jsonkit.of_json_error_to_string error)
  | exception Jsonkit.Of_string_error message -> Failed message

exception Left_the_direct_path

let path reader input =
  match
    Jsonkit_reader.of_string
      ~fallback:(fun _ -> raise Left_the_direct_path)
      reader input
  with
  | _ -> "direct"
  | exception Left_the_direct_path -> "fallback"

let agree ~of_json ~reader input =
  let expected = outcome (fun () -> of_json (Jsonkit.of_string input)) in
  let actual =
    outcome (fun () -> Jsonkit.Reader.of_string ~of_json reader input)
  in
  let detached =
    outcome (fun () ->
        Jsonkit.Reader.of_string ~detach_strings:true ~of_json reader
          input)
  in
  expected = actual && expected = detached

let check ~of_json ~reader input =
  print "%s -> %s, agrees: %b" (visible input) (path reader input)
    (agree ~of_json ~reader input)

let characters_to_insert =
  [ " "; "\n"; "\t"; "\""; "\\"; ","; ":"; "0"; "-"; "."; "e"; "x" ]
  @ [ "{"; "}"; "["; "]"; "null"; backslash ^ "u0041"; "\001" ]

let mutations input =
  let length = String.length input in
  List.concat
    (List.init (length + 1) (fun i ->
         let before = String.sub input 0 i in
         let after = String.sub input i (length - i) in
         let insertions =
           List.map
             (fun inserted -> before ^ inserted ^ after)
             characters_to_insert
         in
         if i < length then
           let after_deletion =
             String.sub input (i + 1) (length - i - 1)
           in
           (before ^ after_deletion) :: insertions
         else insertions))

let check_mutations name ~of_json ~reader input =
  let mutated = mutations input in
  let disagreements =
    List.filter (fun input -> not (agree ~of_json ~reader input)) mutated
  in
  print "%s: %i mutations of the encoded value, %i disagreements" name
    (List.length mutated)
    (List.length disagreements);
  List.iter
    (fun input -> print "  disagrees on: %s" (visible input))
    disagreements

module Scalars = struct
  let test () =
    print "** Scalars **";
    let int = check ~of_json:int_of_json ~reader:int_json_reader in
    List.iter int
      [ "0"; "-1"; "42"; "2147483647"; "-2147483648"; "123456789012" ];
    List.iter int
      [ "-0"; "01"; "1.0"; "1e2"; "1.5"; "9007199254740993"; "+1"; "" ];
    let float = check ~of_json:float_of_json ~reader:float_json_reader in
    List.iter float
      [ "0"; "-0"; "1.5"; "-9.1393"; "0.1"; "123456789.123456" ];
    List.iter float
      [ "1e3"; "1E-3"; "1.7976931348623157e308"; "0.30000000000000004" ];
    List.iter float [ "1."; ".5"; "1e"; "01.5"; "-"; "NaN"; "Infinity" ];
    print "-0 keeps its sign: %b"
      (same_value
         (Jsonkit.Reader.of_string ~of_json:float_of_json
            float_json_reader "-0")
         (-0.));
    print "0.1 + 0.2 as written: %b"
      (same_value
         (Jsonkit.Reader.of_string ~of_json:float_of_json
            float_json_reader "0.30000000000000004")
         (0.1 +. 0.2));
    let string =
      check ~of_json:string_of_json ~reader:string_json_reader
    in
    List.iter string
      [
        {|""|};
        {|"plain"|};
        {|"a longer string that gets detached"|};
        {|"quote \" and backslash \\"|};
        {|"|} ^ backslash ^ {|u00e9|} ^ backslash ^ {|n"|};
        {|"ends with a backslash \\"|};
        {|"bad escape \x"|};
        {|"unterminated|};
        "\"raw\ttab\"";
        "\"raw\nnewline\"";
      ];
    let bool = check ~of_json:bool_of_json ~reader:bool_json_reader in
    List.iter bool [ "true"; "false"; "truee"; "tru"; "1" ];
    let unit = check ~of_json:unit_of_json ~reader:unit_json_reader in
    List.iter unit [ "null"; "nul"; "0" ];
    let int64 = check ~of_json:int64_of_json ~reader:int64_json_reader in
    List.iter int64 [ {|"9223372036854775807"|}; {|"-5"|}; {|"x"|}; "5" ]
end

module Containers = struct
  type ints = int list [@@deriving json, json_reader]
  type floats = float array [@@deriving json, json_reader]
  type maybe = string option list [@@deriving json, json_reader]
  type outcome = (int, string) result [@@deriving json, json_reader]
  type pair = int * string [@@deriving json, json_reader]
  type nested = (int * float list) list [@@deriving json, json_reader]

  let test () =
    print "** Containers **";
    let ints = check ~of_json:ints_of_json ~reader:ints_json_reader in
    List.iter ints [ "[]"; "[1]"; "[1,2,3]"; "[1, 2]"; "[1,]"; "[,1]" ];
    List.iter ints [ "[1 ,2]"; "[1,2"; "[1,2]]"; "{}"; "null" ];
    let floats =
      check ~of_json:floats_of_json ~reader:floats_json_reader
    in
    List.iter floats [ "[]"; "[1.5,2,-3e2]"; "[1.5,null]" ];
    let maybe = check ~of_json:maybe_of_json ~reader:maybe_json_reader in
    List.iter maybe [ {|[null,"a",null]|}; "[null]"; "[1]" ];
    let outcome =
      check ~of_json:outcome_of_json ~reader:outcome_json_reader
    in
    List.iter outcome
      [ {|["Ok",1]|}; {|["Error","no"]|}; {|["Ok"]|}; {|["Other",1]|} ];
    let pair = check ~of_json:pair_of_json ~reader:pair_json_reader in
    List.iter pair
      [ {|[1,"a"]|}; {|[1,"a",2]|}; {|[1]|}; {|["a",1]|}; {|[1, "a"]|} ];
    let nested =
      check ~of_json:nested_of_json ~reader:nested_json_reader
    in
    List.iter nested [ "[[1,[1.5,2.5]],[2,[]]]"; "[[1,[1.5,2.5]],[2]]" ];
    check ~of_json:[%of_json: (string * bool) list]
      ~reader:[%json_reader: (string * bool) list]
      {|[["a",true],["b",false]]|}
end

module Records = struct
  type point = { x : int; y : int } [@@deriving json, json_reader]

  type renamed = {
    first_name : string; [@json.key "firstName"]
    age : int option; [@json.option]
    tags : string list; [@json.default []]
    origin : point;
  }
  [@@deriving json, json_reader]

  type strict = { only : int }
  [@@deriving json, json_reader] [@@json.disallow_extra_fields]

  type empty = { nothing : unit option [@json.option] }
  [@@deriving json, json_reader]

  let test () =
    print "** Records **";
    let point = check ~of_json:point_of_json ~reader:point_json_reader in
    List.iter point
      [
        {|{"x":1,"y":2}|};
        {|{"y":2,"x":1}|};
        {|{"x":1,"y":2,"z":3}|};
        {|{"z":{"a":[1,{"b":null}],"c":"}"},"x":1,"y":2}|};
        {|{"x":1,"x":5,"y":2}|};
        {|{"x":1,"y":2,"x":5}|};
        {|{"x":"bad","x":5,"y":2}|};
        {|{"|} ^ backslash ^ {|u0078":1,"y":2}|};
        {|{"x":1,"y":2,"|} ^ backslash ^ {|u0078":7}|};
        {|{"x": 1, "y": 2}|};
        {|{"x":1}|};
        {|{"x":1,"y":null}|};
        {|{"x":1,"y":2,}|};
        {|{"x":1,"y":2,"z":01}|};
        {|{"x":1,"y":2,"z":"bad \x escape"}|};
        {|{"x":1,"y":2,"z":[1,]}|};
        {|{"x":1,"y":2}trailing|};
        "{\"x\":1,\"y\":2,\"z\":\"raw\ttab\"}";
        "{\"x\":1,\n\"y\":2}";
        {|{}|};
        {|[]|};
      ];
    let renamed =
      check ~of_json:renamed_of_json ~reader:renamed_json_reader
    in
    List.iter renamed
      [
        {|{"firstName":"a","age":3,"tags":["t"],"origin":{"x":1,"y":2}}|};
        {|{"firstName":"a","origin":{"x":1,"y":2}}|};
        {|{"firstName":"a","age":null,"origin":{"x":1,"y":2}}|};
        {|{"origin":{"y":2,"x":1},"firstName":"a"}|};
        {|{"first_name":"a","origin":{"x":1,"y":2}}|};
        {|{"firstName":"a","tags":null,"origin":{"x":1,"y":2}}|};
      ];
    let strict =
      check ~of_json:strict_of_json ~reader:strict_json_reader
    in
    List.iter strict [ {|{"only":1}|}; {|{"only":1,"more":2}|} ];
    let empty = check ~of_json:empty_of_json ~reader:empty_json_reader in
    List.iter empty [ "{}"; {|{"nothing":null}|}; {|{"other":1}|} ];
    check_mutations "point" ~of_json:point_of_json
      ~reader:point_json_reader {|{"x":1,"y":-20}|};
    check_mutations "renamed" ~of_json:renamed_of_json
      ~reader:renamed_json_reader
      {|{"firstName":"a\"b","age":3,"tags":["t","u"],"origin":{"x":1,"y":2}}|}
end

module Variants = struct
  type shape =
    | Dot
    | Circle of float
    | Rect of float * float
    | Label of { text : string; size : int [@json.default 12] }
    | Renamed [@json.name "other-name"]
  [@@deriving json, json_reader]

  type compact = Up | Down | Sideways of int
  [@@deriving json, json_reader] [@@json.compact_variants]

  type poly = [ `A | `B of int | `C of string * bool ]
  [@@deriving json, json_reader]

  type extended = [ poly | `D ] [@@deriving json, json_reader]

  type open_ended =
    | Known of int
    | Unknown of Jsonkit.unknown_variant_case [@json.catch_all]
  [@@deriving json, json_reader]

  type anything =
    | Exactly of int
    | Whatever of Jsonkit.t [@json.allow_any]
  [@@deriving json, json_reader]

  type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree
  [@@deriving json, json_reader]

  let test () =
    print "** Variants **";
    let shape = check ~of_json:shape_of_json ~reader:shape_json_reader in
    List.iter shape
      [
        {|["Dot"]|};
        {|["Circle",1.5]|};
        {|["Rect",1,2]|};
        {|["Label",{"text":"t","size":3}]|};
        {|["Label",{"text":"t"}]|};
        {|["Label",{"size":3,"text":"t"}]|};
        {|["other-name"]|};
        {|["Renamed"]|};
        {|"Dot"|};
        {|["Dot",1]|};
        {|["Circle"]|};
        {|["Rect",1]|};
        {|["Rect",1,2,3]|};
        {|["D|} ^ backslash ^ {|u006ft"]|};
        {|[ "Dot" ]|};
        {|[]|};
      ];
    let compact =
      check ~of_json:compact_of_json ~reader:compact_json_reader
    in
    List.iter compact
      [ {|"Up"|}; {|"Down"|}; {|["Sideways",3]|}; {|["Up"]|}; {|"Left"|} ];
    let poly = check ~of_json:poly_of_json ~reader:poly_json_reader in
    List.iter poly
      [ {|["A"]|}; {|["B",1]|}; {|["C","s",true]|}; {|["D"]|} ];
    let extended =
      check ~of_json:extended_of_json ~reader:extended_json_reader
    in
    List.iter extended [ {|["A"]|}; {|["D"]|}; {|["E"]|} ];
    let open_ended =
      check ~of_json:open_ended_of_json ~reader:open_ended_json_reader
    in
    List.iter open_ended
      [ {|["Known",1]|}; {|["Later",1,"x"]|}; {|"Bare"|} ];
    let anything =
      check ~of_json:anything_of_json ~reader:anything_json_reader
    in
    List.iter anything [ {|["Exactly",1]|}; {|{"free":["form"]}|} ];
    let tree =
      check
        ~of_json:(tree_of_json int_of_json)
        ~reader:(tree_json_reader int_json_reader)
    in
    List.iter tree
      [
        {|["Leaf"]|};
        {|["Node",["Leaf"],1,["Node",["Leaf"],2,["Leaf"]]]|};
        {|["Node",["Leaf"],"x",["Leaf"]]|};
      ];
    check_mutations "shape list" ~of_json:[%of_json: shape list]
      ~reader:[%json_reader: shape list]
      {|[["Dot"],["Circle",1.5],["Label",{"text":"t","size":3}]]|};
    check_mutations "compact" ~of_json:compact_of_json
      ~reader:compact_json_reader {|["Sideways",3]|}
end

module Handwritten = struct
  type celsius = float

  let celsius_of_json json = float_of_json json -. 273.15
  let celsius_to_json celsius = float_to_json (celsius +. 273.15)
  let celsius_json_reader = Jsonkit.Reader.of_json celsius_of_json

  type reading = { place : string; temperature : celsius }
  [@@deriving json, json_reader]

  let test () =
    print "** Handwritten **";
    let reading =
      check ~of_json:reading_of_json ~reader:reading_json_reader
    in
    List.iter reading
      [
        {|{"place":"lab","temperature":300.15}|};
        {|{"place":"lab","temperature":"hot"}|};
      ]
end

let test () =
  Scalars.test ();
  Containers.test ();
  Records.test ();
  Variants.test ();
  Handwritten.test ()
