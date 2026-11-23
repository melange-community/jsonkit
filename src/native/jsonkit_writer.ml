external format_float : string -> float -> string = "caml_format_float"

type 'a t = 'a -> Buffer.t -> unit
type obj = { buffer : Buffer.t; mutable is_empty : bool }

let to_string ?(size = 1024) write v =
  let buffer = Buffer.create size in
  write v buffer;
  Buffer.contents buffer

let json v buffer = Yojson.Basic.write_json buffer v

let via_to_json to_json v buffer =
  Yojson.Basic.write_json buffer (to_json v)

let needs_escape =
  let table = Bytes.make 256 '\001' in
  for code = 0x20 to 0x7e do
    Bytes.set table code '\000'
  done;
  Bytes.set table (Char.code '"') '\001';
  Bytes.set table (Char.code '\\') '\001';
  for code = 0x80 to 0xff do
    Bytes.set table code '\000'
  done;
  table

let is_plain v =
  let length = String.length v in
  let rec scan i =
    i = length
    || Bytes.unsafe_get needs_escape (Char.code (String.unsafe_get v i))
       = '\000'
       && scan (i + 1)
  in
  scan 0

let string v buffer =
  if is_plain v then (
    Buffer.add_char buffer '"';
    Buffer.add_string buffer v;
    Buffer.add_char buffer '"')
  else Yojson.Basic.write_string buffer v

let literal v buffer = Buffer.add_string buffer v
let bool v buffer = Yojson.Basic.write_bool buffer v
let int v buffer = Yojson.Basic.write_int buffer v

let is_all_digits s =
  let n = String.length s in
  let rec loop i =
    if i = n then true
    else
      match String.unsafe_get s i with
      | '0' .. '9' | '-' -> loop (i + 1)
      | _ -> false
  in
  loop 0

let float v buffer =
  match classify_float v with
  | FP_nan -> Buffer.add_string buffer "NaN"
  | FP_infinite ->
      Buffer.add_string buffer
        (if v > 0. then "Infinity" else "-Infinity")
  | FP_zero ->
      Buffer.add_string buffer (if 1. /. v < 0. then "-0.0" else "0.0")
  | FP_normal | FP_subnormal ->
      if Float.is_integer v && Float.abs v < 1e16 then (
        Yojson.Basic.write_int buffer (int_of_float v);
        Buffer.add_string buffer ".0")
      else
        let s = format_float "%.16g" v in
        let s =
          if float_of_string s = v then s else format_float "%.17g" v
        in
        Buffer.add_string buffer s;
        if is_all_digits s then Buffer.add_string buffer ".0"

let unit () buffer = Yojson.Basic.write_null buffer ()
let int64 v buffer = Yojson.Basic.write_string buffer (Int64.to_string v)

let option write v buffer =
  match v with
  | None -> Yojson.Basic.write_null buffer ()
  | Some v -> write v buffer

let list write vs buffer =
  Buffer.add_char buffer '[';
  let rec loop = function
    | [] -> ()
    | [ v ] -> write v buffer
    | v :: vs ->
        write v buffer;
        Buffer.add_char buffer ',';
        loop vs
  in
  loop vs;
  Buffer.add_char buffer ']'

let array write vs buffer =
  Buffer.add_char buffer '[';
  let last = Array.length vs - 1 in
  Array.iteri
    (fun i v ->
      write v buffer;
      if i <> last then Buffer.add_char buffer ',')
    vs;
  Buffer.add_char buffer ']'

let result write_ok write_error v buffer =
  match v with
  | Ok v ->
      Buffer.add_string buffer {|["Ok",|};
      write_ok v buffer;
      Buffer.add_char buffer ']'
  | Error v ->
      Buffer.add_string buffer {|["Error",|};
      write_error v buffer;
      Buffer.add_char buffer ']'

let obj buffer write_fields =
  Buffer.add_char buffer '{';
  write_fields { buffer; is_empty = true };
  Buffer.add_char buffer '}'

let separate o =
  if o.is_empty then o.is_empty <- false else Buffer.add_char o.buffer ','

let key o quoted_key_and_colon =
  separate o;
  Buffer.add_string o.buffer quoted_key_and_colon;
  o.buffer

let key_escaped o name =
  separate o;
  Yojson.Basic.write_string o.buffer name;
  Buffer.add_char o.buffer ':';
  o.buffer

let quote_key name =
  let buffer = Buffer.create (String.length name + 3) in
  Yojson.Basic.write_string buffer name;
  Buffer.add_char buffer ':';
  Buffer.contents buffer

module Primitives = struct
  let string_to_json_buffer = string
  let bool_to_json_buffer = bool
  let int_to_json_buffer = int
  let int64_to_json_buffer = int64
  let float_to_json_buffer = float
  let unit_to_json_buffer = unit
  let option_to_json_buffer = option
  let list_to_json_buffer = list
  let array_to_json_buffer = array
  let result_to_json_buffer = result
end
