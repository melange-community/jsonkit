open Jsonkit.Primitives

type variant =
  | A
  | Foo
  | B of int
  | C of int * string
  | D of { x : int; y : string }
[@@deriving json]

type j = {
  a : variant;
  foo: variant list;
  b : string;
  c : int list;
  d : int * float list * string;
}
[@@deriving json]
[@@json.disallow_extra_fields]

let () =
  In_channel.with_open_bin Sys.argv.(1) (fun file ->
      file
      |> In_channel.input_all
      |> Yojson.Basic.from_string
      |> j_of_json
      |> j_to_json
      |> Yojson.Basic.pretty_to_string
      |> print_endline)
