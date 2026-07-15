(* Encoding a JSON data structure using Jsonkit.Encode *)

(* prints ["foo", "bar"] *)
let _ =
  [| "foo"; "bar" |]
  |> Jsonkit.To_json.string_array
  |> Jsonkit.to_string
  |> Js.log

(* prints ["foo", "bar"] *)
let _ =
  [| "foo"; "bar" |]
  |> Js.Array.map ~f:Jsonkit.To_json.string
  |> Jsonkit.To_json.json_array
  |> Jsonkit.to_string
  |> Js.log

(* prints { x: 42, foo: 'bar' } *)
let _ =
  Jsonkit.To_json.(
    json_dict (Js.Dict.fromList [ "x", int 42; "foo", string "bar" ]))
  |> Js.log

(* Advanced example: encode a record *)
type line = { start : point; end_ : point; thickness : int option }
and point = { x : float; y : float }

module Encode = struct
  let point r =
    let open! Jsonkit.To_json in
    json_dict (Js.Dict.fromList [ "x", float r.x; "y", float r.y ])

  let line r =
    Jsonkit.To_json.(
      json_dict
        (Js.Dict.fromList
           [
             "start", point r.start;
             "end", point r.end_;
             ( "thickness",
               match r.thickness with Some x -> int x | None -> unit () );
           ]))
end

let data =
  {
    start = { x = 1.1; y = -0.4 };
    end_ = { x = 5.3; y = 3.8 };
    thickness = Some 2;
  }

let _ = data |> Encode.line |> Js.log
