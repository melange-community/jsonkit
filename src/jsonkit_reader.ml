type t = {
  source : string;
  mutable position : int;
  mutable next_backslash : int;
  mutable speculating : bool;
  detach_strings : bool;
}

type 'a reader = t -> 'a

exception Fallback

external char_code_at : string -> int -> int = "charCodeAt" [@@mel.send]
external slice : string -> int -> int -> string = "slice" [@@mel.send]

external index_from : string -> string -> int -> int = "indexOf"
[@@mel.send]

external starts_with_at : string -> string -> int -> bool = "startsWith"
[@@mel.send]

external parse_json : string -> Js.Json.t = "parse" [@@mel.scope "JSON"]
external number_of_string : string -> float = "Number"
external matches : Js.Re.t -> string -> bool = "test" [@@mel.send]
external push_item : 'a array -> 'a -> unit = "push" [@@mel.send]

let push items item = push_item items item
let absent = Obj.repr (ref ())
let fallback () = raise Fallback
let position r = r.position
let speculating r = r.speculating

let stop_speculating r start =
  r.position <- start;
  r.speculating <- false

let[@inline] lit r literal =
  if starts_with_at r.source literal r.position then (
    r.position <- r.position + String.length literal;
    true)
  else false

let[@inline] char r code =
  if char_code_at r.source r.position = code then
    r.position <- r.position + 1
  else raise Fallback

let[@inline] more r closing =
  let code = char_code_at r.source r.position in
  r.position <- r.position + 1;
  if code = 44 then true
  else if code = closing then false
  else raise Fallback

let more_members r = more r 125
let more_items r = more r 93

let array_start r =
  char r 91;
  if char_code_at r.source r.position = 93 then begin
    r.position <- r.position + 1;
    false
  end
  else true

let closing_quote r opening =
  let source = r.source in
  let closing = index_from source "\"" (opening + 1) in
  if closing < 0 then raise Fallback;
  if r.next_backslash < opening then begin
    let backslash = index_from source "\\" opening in
    r.next_backslash <- (if backslash < 0 then max_int else backslash)
  end;
  if r.next_backslash > closing then closing
  else begin
    let length = String.length source in
    let i = ref r.next_backslash in
    let code = ref 92 in
    while !code <> 34 do
      if !i >= length then raise Fallback;
      i := if !code = 92 then !i + 2 else !i + 1;
      code := char_code_at source !i
    done;
    - !i
  end

let sliced_string_min_length = 13

let string r =
  let source = r.source in
  let opening = r.position in
  if char_code_at source opening <> 34 then raise Fallback;
  let closing = closing_quote r opening in
  if closing > 0 then begin
    r.position <- closing + 1;
    let length = closing - opening - 1 in
    if r.detach_strings && length >= sliced_string_min_length then
      slice (" " ^ slice source (opening + 1) closing) 1 (length + 1)
    else slice source (opening + 1) closing
  end
  else begin
    r.position <- 1 - closing;
    (Obj.magic (parse_json (slice source opening (1 - closing))) : string)
  end

let skip_string r =
  let source = r.source in
  let opening = r.position in
  if char_code_at source opening <> 34 then raise Fallback;
  let closing = closing_quote r opening in
  if closing > 0 then r.position <- closing + 1
  else begin
    r.position <- 1 - closing;
    ignore (parse_json (slice source opening (1 - closing)))
  end

let powers_of_ten =
  [|
    1.;
    1e1;
    1e2;
    1e3;
    1e4;
    1e5;
    1e6;
    1e7;
    1e8;
    1e9;
    1e10;
    1e11;
    1e12;
    1e13;
    1e14;
    1e15;
  |]

let exactly_representable_digits = 15

let float r =
  let source = r.source in
  let start = r.position in
  let p = ref start in
  let negative = char_code_at source !p = 45 in
  if negative then incr p;
  let code = ref (char_code_at source !p) in
  if not (!code >= 48 && !code <= 57) then raise Fallback;
  let starts_with_zero = !code = 48 in
  let mantissa = ref 0. in
  let integer_digits = ref 0 in
  while !code >= 48 && !code <= 57 do
    mantissa := (!mantissa *. 10.) +. float_of_int (!code - 48);
    incr integer_digits;
    incr p;
    code := char_code_at source !p
  done;
  if starts_with_zero && !integer_digits > 1 then raise Fallback;
  let fraction_digits = ref 0 in
  if !code = 46 then begin
    incr p;
    code := char_code_at source !p;
    if not (!code >= 48 && !code <= 57) then raise Fallback;
    while !code >= 48 && !code <= 57 do
      mantissa := (!mantissa *. 10.) +. float_of_int (!code - 48);
      incr fraction_digits;
      incr p;
      code := char_code_at source !p
    done
  end;
  let has_exponent = !code = 101 || !code = 69 in
  if has_exponent then begin
    incr p;
    code := char_code_at source !p;
    if !code = 43 || !code = 45 then begin
      incr p;
      code := char_code_at source !p
    end;
    if not (!code >= 48 && !code <= 57) then raise Fallback;
    while !code >= 48 && !code <= 57 do
      incr p;
      code := char_code_at source !p
    done
  end;
  r.position <- !p;
  if
    has_exponent
    || !integer_digits + !fraction_digits > exactly_representable_digits
  then number_of_string (slice source start !p)
  else
    let magnitude =
      if !fraction_digits = 0 then !mantissa
      else !mantissa /. Array.unsafe_get powers_of_ten !fraction_digits
    in
    if negative then -.magnitude else magnitude

let int32_safe_digits = 9

let int r : int =
  let source = r.source in
  let start = r.position in
  let p = ref start in
  let negative = char_code_at source !p = 45 in
  if negative then incr p;
  let code = ref (char_code_at source !p) in
  if not (!code >= 48 && !code <= 57) then raise Fallback;
  let starts_with_zero = !code = 48 in
  let magnitude = ref 0 in
  let digits = ref 0 in
  while !code >= 48 && !code <= 57 do
    magnitude := (!magnitude * 10) + (!code - 48);
    incr digits;
    incr p;
    code := char_code_at source !p
  done;
  if
    (starts_with_zero && (!digits > 1 || negative))
    || !digits > exactly_representable_digits
    || !code = 46
    || !code = 101
    || !code = 69
  then raise Fallback;
  r.position <- !p;
  if !digits <= int32_safe_digits then
    if negative then - !magnitude else !magnitude
  else (Obj.magic (number_of_string (slice source start !p)) : int)

let bool r =
  if lit r "true" then true
  else if lit r "false" then false
  else raise Fallback

let[@inline] null r =
  char_code_at r.source r.position = 110 && lit r "null"

let unit r = if not (null r) then raise Fallback

let int64 r =
  match Int64.of_string_opt (string r) with
  | Some value -> value
  | None -> raise Fallback

let option element r = if null r then None else Some (element r)

let list element r =
  char r 91;
  if char_code_at r.source r.position = 93 then begin
    r.position <- r.position + 1;
    []
  end
  else
    let[@tail_mod_cons] rec items () =
      let item = element r in
      if more r 93 then item :: items () else [ item ]
    in
    items ()

let array element r =
  char r 91;
  let items = [||] in
  if char_code_at r.source r.position = 93 then
    r.position <- r.position + 1
  else begin
    let continue = ref true in
    while !continue do
      push items (element r);
      continue := more r 93
    done
  end;
  items

let result ok error r =
  if lit r "[\"Ok\"," then begin
    let value = ok r in
    char r 93;
    Ok value
  end
  else if lit r "[\"Error\"," then begin
    let value = error r in
    char r 93;
    Error value
  end
  else raise Fallback

let rec skip r =
  match char_code_at r.source r.position with
  | 34 -> skip_string r
  | 123 ->
      r.position <- r.position + 1;
      if char_code_at r.source r.position = 125 then
        r.position <- r.position + 1
      else begin
        let continue = ref true in
        while !continue do
          skip_string r;
          char r 58;
          skip r;
          continue := more r 125
        done
      end
  | 91 ->
      r.position <- r.position + 1;
      if char_code_at r.source r.position = 93 then
        r.position <- r.position + 1
      else begin
        let continue = ref true in
        while !continue do
          skip r;
          continue := more r 93
        done
      end
  | 116 -> if not (lit r "true") then raise Fallback
  | 102 -> if not (lit r "false") then raise Fallback
  | 110 -> if not (lit r "null") then raise Fallback
  | _ -> ignore (float r)

let object_start r =
  char r 123;
  if char_code_at r.source r.position = 125 then begin
    r.position <- r.position + 1;
    false
  end
  else true

let member_start r =
  char r 34;
  char_code_at r.source r.position

let skip_member r =
  let closing = closing_quote r (r.position - 1) in
  if closing < 0 then raise Fallback;
  r.position <- closing + 1;
  char r 58;
  skip r

let of_json decode r =
  let start = r.position in
  skip r;
  decode (parse_json (slice r.source start r.position))

let control_character = [%re "/[\\x00-\\x1f]/"]

let read ~detach_strings reader source =
  let r =
    {
      source;
      position = 0;
      next_backslash = -1;
      speculating = true;
      detach_strings;
    }
  in
  let value = reader r in
  if r.position <> String.length source then raise Fallback;
  value

let of_string ?(detach_strings = false) ~fallback reader source =
  if matches control_character source then fallback source
  else
    match read ~detach_strings reader source with
    | value -> value
    | exception _ -> fallback source
