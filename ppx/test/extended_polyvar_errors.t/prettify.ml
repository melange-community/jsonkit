open Jsonkit.Primitives


type polyvar = [ `C of int * string ]
[@@deriving json]

type parent = [ `P | polyvar ]
[@@deriving json]

type polyvars = 
{ extended : parent;
  not_extended : polyvar;
}
[@@deriving json]

let () =
  In_channel.with_open_bin Sys.argv.(1) (fun file ->
      file
      |> In_channel.input_all
      |> Yojson.Basic.from_string
      |> polyvars_of_json
      |> polyvars_to_json
      |> Yojson.Basic.pretty_to_string
      |> print_endline)
