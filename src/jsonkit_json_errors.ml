exception Of_string_error of string

type of_json_error = Json_error of string | Unexpected_variant of string

exception Of_json_error of of_json_error

external js_length : string -> int = "length" [@@mel.get]
external js_slice : string -> int -> int -> string = "slice" [@@mel.send]
external js_index_of : string -> string -> int = "indexOf" [@@mel.send]

let quoted str = Js.Json.stringify (Js.Json.string str)

(* [string_of_float] spells these "nan", "inf" and "-inf", and always leaves a
   decimal point behind; JavaScript does neither. Error messages are compared
   against the native backend's, so follow OCaml here. *)
let float_to_string f =
  if f <> f then "nan"
  else if not (Js.Float.isFinite f) then if f > 0. then "inf" else "-inf"
  else
    let s = Js.Float.toString f in
    if js_index_of s "." >= 0 || js_index_of s "e" >= 0 then s
    else s ^ "."

let with_buffer f =
  let parts = [||] in
  f (fun piece -> ignore (Js.Array.push ~value:piece parts));
  Js.Array.join ~sep:"" parts

let iteri_last f li =
  let rec loop i li =
    match li with
    | [] -> ()
    | [ elt ] -> f ~is_last:true i elt
    | elt :: li ->
        f ~is_last:false i elt;
        loop (i + 1) li
  in
  loop 0 li

let show_json_type json =
  json |> Jsonkit_json_classify.classify |> function
  | `Assoc _ -> "object"
  | `Bool _ -> "bool"
  | `Float _ -> "float"
  | `Int _ -> "int"
  | `List _ -> "array"
  | `Null -> "null"
  | `String _ -> "string"

let show_json_error ?depth ?width json =
  with_buffer (fun emit ->
      let rec loop ?depth json =
        let json = Jsonkit_json_classify.classify json in
        let depth =
          match depth with Some i -> Some (i - 1) | None -> None
        in
        match depth with
        | Some 0 -> emit "_"
        | _ -> (
            match json with
            | `Assoc assoc ->
                emit "{";
                iteri_last
                  (fun ~is_last i (k, v) ->
                    match width with
                    | Some width when i = width -> emit "..."
                    | Some width when i > width -> ()
                    | _ ->
                        emit {|"|};
                        emit k;
                        emit {|": |};
                        let depth =
                          match depth with
                          | Some i -> Some (i - 1)
                          | None -> None
                        in
                        loop ?depth v;
                        if not is_last then emit {|, |})
                  assoc;
                emit "}"
            | `Bool bool -> emit (if bool then "true" else "false")
            | `Float float -> emit (float_to_string float)
            | `Int int -> emit (Js.Int.toString int)
            | `List li ->
                emit "[";
                iteri_last
                  (fun ~is_last i elt ->
                    match width with
                    | Some width when i = width -> emit "..."
                    | Some width when i > width -> ()
                    | _ ->
                        loop ?depth elt;
                        if not is_last then emit ", ")
                  li;
                emit "]"
            | `Null -> emit "null"
            | `String str -> (
                let len = js_length str in
                match width with
                | Some width
                  when len > (width * 2) + 5
                       (* I add 5 to account for the [" ... "] I am adding in that case *)
                  ->
                    emit (quoted (js_slice str 0 width ^ " ... "))
                | _ -> emit (quoted str)))
      in

      let depth =
        match depth with Some i -> Some (i + 1) | None -> None
      in
      (loop ?depth) json)

let of_json_msg_error msg = raise (Of_json_error (Json_error msg))

let of_json_error ?(depth = 2) ?(width = 8) ~json msg =
  of_json_msg_error
    (with_buffer (fun emit ->
         emit msg;
         emit " but got ";
         emit (show_json_error ~depth ~width json)))

let of_json_msg_unexpected_variant msg =
  raise (Of_json_error (Unexpected_variant msg))

let of_json_unexpected_variant ?(depth = 2) ?(width = 8) ~json msg =
  of_json_msg_unexpected_variant
    (with_buffer (fun emit ->
         emit msg;
         emit " but got ";
         emit (show_json_error ~depth ~width json)))

let of_json_error_type_mismatch json expected =
  of_json_msg_error
    (with_buffer (fun emit ->
         emit "expected ";
         emit expected;
         emit " but got ";
         emit (show_json_type json);
         emit ": ";
         emit (show_json_error ~depth:2 ~width:8 json)))

let of_json_error_to_string = function
  | Json_error msg -> msg
  | Unexpected_variant msg -> "unexpected variant: " ^ msg
