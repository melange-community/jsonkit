(* Decoding a fixed JSON data structure using Jsonkit.Of_json *)
let mapJsonObjectString f decoder (encoder : int -> Js.Json.t) str =
  let json = Jsonkit.of_string str in
  Jsonkit.Of_json.(js_dict decoder json)
  |> Js.Dict.map ~f:(fun[@u] v -> f v)
  |> Jsonkit.To_json.js_dict encoder
  |> Jsonkit.to_string

let sum = Array.fold_left ( + ) 0

(* prints `{ "foo": 6, "bar": 24 }` *)
let () =
  Js.log
  @@ mapJsonObjectString sum
       Jsonkit.Of_json.(array int)
       Jsonkit.To_json.int
       {|
      {
        "foo": [1, 2, 3],
        "bar": [9, 8, 7]
      }
    |}

(* Error handling *)
let () =
  let json = {|{ "y": 42 } |} |> Jsonkit.of_string in
  match Jsonkit.Of_json.(field "x" int json) with
  | x -> Js.log x
  | exception Jsonkit.Of_json_error err ->
      Js.log ("Error:" ^ Jsonkit.of_json_error_to_string err)
