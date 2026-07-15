exception Of_string_error of string

type of_json_error = Json_error of string | Unexpected_variant of string

exception Of_json_error of of_json_error

let with_buffer f =
  let buffer = Buffer.create 1 in
  f (Buffer.add_string buffer);
  Buffer.contents buffer

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
  json |> Jsonkit_classify.classify |> function
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
        let json = Jsonkit_classify.classify json in
        let depth = Option.map (fun i -> i - 1) depth in
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
                        let depth = Option.map (fun i -> i - 1) depth in
                        loop ?depth v;
                        if not is_last then emit {|, |})
                  assoc;
                emit "}"
            | `Bool bool -> emit (if bool then "true" else "false")
            | `Float float -> emit (string_of_float float)
            | `Int int -> emit (string_of_int int)
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
                let len = String.length str in
                match width with
                | Some width
                  when len > (width * 2) + 5
                       (* I add 5 to account for the [" ... "] I am adding in that case *)
                  ->
                    emit {|"|};
                    emit (String.escaped (String.sub str 0 width));
                    emit " ... ";
                    emit {|"|}
                | _ ->
                    emit {|"|};
                    emit (String.escaped str);
                    emit {|"|}))
      in

      (loop ?depth:(Option.map (fun i -> i + 1) depth)) json)

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

(* only use for cases where we need granular handling of the error (e.g. arr)*)
let dangerous_of_json_error ?(depth = 2) ?(width = 8) ~json msg =
  of_json_msg_error
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
