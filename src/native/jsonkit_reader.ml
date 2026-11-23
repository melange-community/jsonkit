open Jsonkit_json_errors

type 'a t = Yojson.lexer_state -> Lexing.lexbuf -> 'a

let space = Yojson.Basic.read_space

let peek_char p lb =
  space p lb;
  if lb.Lexing.lex_curr_pos < lb.Lexing.lex_buffer_len then
    Some (Bytes.get lb.Lexing.lex_buffer lb.Lexing.lex_curr_pos)
  else None

let json p lb =
  space p lb;
  Yojson.Basic.read_json p lb

let skip p lb =
  space p lb;
  Yojson.Basic.skip_json p lb

let via_of_json of_json p lb = of_json (json p lb)

let string p lb =
  space p lb;
  Yojson.Basic.read_string p lb

let bool p lb =
  space p lb;
  Yojson.Basic.read_bool p lb

let int p lb =
  space p lb;
  Yojson.Basic.read_int p lb

let float p lb =
  space p lb;
  Yojson.Basic.read_number p lb

let unit p lb =
  space p lb;
  Yojson.Basic.read_null p lb

let int64 p lb =
  let s = string p lb in
  match Int64.of_string_opt s with
  | Some v -> v
  | None -> of_json_error_type_mismatch (`String s) "int64 as string"

let option read p lb =
  space p lb;
  if Yojson.Basic.read_null_if_possible p lb then None
  else Some (read p lb)

let list read p lb =
  space p lb;
  Yojson.Basic.read_list read p lb

let array read p lb =
  space p lb;
  Yojson.Basic.read_array read p lb

let array_start p lb =
  space p lb;
  Yojson.Basic.read_lbr p lb

let array_next p lb =
  space p lb;
  Yojson.Basic.read_array_sep p lb

let array_end p lb =
  space p lb;
  match Yojson.Basic.read_array_end lb with
  | () -> of_json_msg_error "expected the end of a JSON array"
  | exception Yojson.End_of_array -> ()

let array_is_empty p lb =
  space p lb;
  match Yojson.Basic.read_array_end lb with
  | () -> false
  | exception Yojson.End_of_array -> true

let array_has_next p lb =
  space p lb;
  match Yojson.Basic.read_array_sep p lb with
  | () -> true
  | exception Yojson.End_of_array -> false

let variant read_case p lb =
  array_start p lb;
  let tag = string p lb in
  let v = read_case tag p lb in
  array_end p lb;
  v

let result read_ok read_error p lb =
  variant
    (fun tag p lb ->
      match tag with
      | "Ok" ->
          array_next p lb;
          Ok (read_ok p lb)
      | "Error" ->
          array_next p lb;
          Error (read_error p lb)
      | _ -> of_json_msg_error {|expected ["Ok", _] or ["Error", _]|})
    p lb

let object_fields read_field p lb =
  space p lb;
  Yojson.Basic.read_lcurl p lb;
  match
    space p lb;
    Yojson.Basic.read_object_end lb;
    let read_one () =
      space p lb;
      let key = Yojson.Basic.read_ident p lb in
      space p lb;
      Yojson.Basic.read_colon p lb;
      read_field key p lb
    in
    read_one ();
    while true do
      space p lb;
      Yojson.Basic.read_object_sep p lb;
      read_one ()
    done
  with
  | () -> ()
  | exception Yojson.End_of_object -> ()

let missing_field type_name field_name =
  of_json_msg_error
    (Printf.sprintf "expected field %S of type %s" field_name type_name)

let run read s =
  let p = Yojson.init_lexer () in
  let lb = Lexing.from_string s in
  match
    let v = read p lb in
    space p lb;
    if Yojson.Basic.read_eof lb then v
    else raise (Of_string_error "expected the end of the JSON input")
  with
  | v -> v
  | exception Yojson.Json_error msg -> raise (Of_string_error msg)
  | exception
      ( Yojson.End_of_array | Yojson.End_of_object | Yojson.End_of_tuple
      | Yojson.End_of_input ) ->
      raise (Of_string_error "unexpected end of JSON input")

let of_string ~of_json read s =
  match run read s with
  | v -> v
  | exception ((Out_of_memory | Stack_overflow) as e) -> raise e
  | exception _ -> of_json (Jsonkit_json.of_string s)

module Primitives = struct
  let string_of_json_lexbuf = string
  let bool_of_json_lexbuf = bool
  let int_of_json_lexbuf = int
  let int64_of_json_lexbuf = int64
  let float_of_json_lexbuf = float
  let unit_of_json_lexbuf = unit
  let option_of_json_lexbuf = option
  let list_of_json_lexbuf = list
  let array_of_json_lexbuf = array
  let result_of_json_lexbuf = result
end
