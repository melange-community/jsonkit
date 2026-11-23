open Jsonkit_json_errors

type t = Js.Json.t

external _unsafeCreateUninitializedArray : int -> 'a array = "Array"
[@@mel.new]

let string (json : t) : string =
  if Js.typeof json = "string" then (Obj.magic json : string)
  else of_json_error ~json "expected a string"

let char (json : t) =
  if Js.typeof json = "string" then
    let s = (Obj.magic json : string) in
    if String.length s = 1 then String.get s 0
    else of_json_error ~json "expected a single-character string"
  else of_json_error ~json "expected a string"

let bool (json : t) : bool =
  if Js.typeof json = "boolean" then (Obj.magic json : bool)
  else of_json_error ~json "expected a boolean"

let is_int value =
  Js.Float.isFinite value && Js.Math.floor_float value == value

let int (json : t) : int =
  if Js.typeof json = "number" then
    let v = (Obj.magic json : float) in
    if is_int v then (Obj.magic v : int)
    else of_json_error ~json "expected an integer"
  else of_json_error ~json "expected an integer"

let int64 (json : t) : int64 =
  if Js.typeof json = "string" then
    let v = (Obj.magic json : string) in
    match Int64.of_string_opt v with
    | Some v -> v
    | None -> of_json_error ~json "expected int64 as string"
  else of_json_error ~json "expected int64 as string"

let float (json : t) : float =
  if Js.typeof json = "number" then (Obj.magic json : float)
  else of_json_error ~json "expected a float"

let unit (json : t) : unit =
  if (Obj.magic json : 'a Js.null) == Js.null then ()
  else of_json_error ~json "expected unit as null"

let array v_of_json (json : t) =
  if Js.Array.isArray json then (
    let source = (Obj.magic (json : Js.Json.t) : Js.Json.t array) in
    let length = Js.Array.length source in
    let target = _unsafeCreateUninitializedArray length in
    for i = 0 to length - 1 do
      let value =
        try v_of_json (Array.unsafe_get source i)
        with Of_json_error err ->
          of_json_msg_error
            (of_json_error_to_string err
            ^ "\n\tin array at index "
            ^ string_of_int i)
      in
      Array.unsafe_set target i value
    done;
    target)
  else of_json_error ~json "expected an array"

let list v_of_json (json : t) : _ list =
  array v_of_json json |> Array.to_list

let option v_of_json (json : t) : _ option =
  if (Obj.magic json : 'a Js.null) == Js.null then None
  else Some (v_of_json json)

let js_null v_of_json (json : t) : _ Js.null =
  if (Obj.magic json : 'a Js.null) == Js.null then Js.null
  else Js.Null.return (v_of_json json)

let js_date json : Js.Date.t = Js.Date.fromString (string json)

let tuple2 decodeA decodeB json : _ * _ =
  if Js.Array.isArray json then
    let source = (Obj.magic (json : Js.Json.t) : Js.Json.t array) in
    let length = Js.Array.length source in
    if length = 2 then
      try
        ( decodeA (Array.unsafe_get source 0),
          decodeB (Array.unsafe_get source 1) )
      with Of_json_error err ->
        of_json_msg_error
          (of_json_error_to_string err ^ "\n\tin pair/tuple2")
    else of_json_error ~json "expected tuple as array of length 2"
  else of_json_error ~json "expected tuple as array"

let tuple3 decodeA decodeB decodeC json : _ * _ * _ =
  if Js.Array.isArray json then
    let source = (Obj.magic (json : Js.Json.t) : Js.Json.t array) in
    let length = Js.Array.length source in
    if length = 3 then
      try
        ( decodeA (Array.unsafe_get source 0),
          decodeB (Array.unsafe_get source 1),
          decodeC (Array.unsafe_get source 2) )
      with Of_json_error err ->
        of_json_msg_error (of_json_error_to_string err ^ "\n\tin tuple3")
    else of_json_error ~json "expected tuple as array of length 3"
  else of_json_error ~json "expected tuple as array"

let tuple4 decodeA decodeB decodeC decodeD json : _ * _ * _ * _ =
  if Js.Array.isArray json then
    let source = (Obj.magic (json : Js.Json.t) : Js.Json.t array) in
    let length = Js.Array.length source in
    if length = 4 then
      try
        ( decodeA (Array.unsafe_get source 0),
          decodeB (Array.unsafe_get source 1),
          decodeC (Array.unsafe_get source 2),
          decodeD (Array.unsafe_get source 3) )
      with Of_json_error err ->
        of_json_msg_error (of_json_error_to_string err ^ "\n\tin tuple4")
    else of_json_error ~json "expected tuple as array of length 4"
  else of_json_error ~json "expected tuple as array"

let js_dict decode json : _ Js.Dict.t =
  if
    Js.typeof json = "object"
    && (not (Js.Array.isArray json))
    && not ((Obj.magic json : 'a Js.null) == Js.null)
  then (
    let source = (Obj.magic (json : Js.Json.t) : Js.Json.t Js.Dict.t) in
    let keys = Js.Dict.keys source in
    let l = Js.Array.length keys in
    let target = Js.Dict.empty () in
    for i = 0 to l - 1 do
      let key = Array.unsafe_get keys i in
      let value =
        try decode (Js.Dict.unsafeGet source key)
        with Of_json_error err ->
          of_json_msg_error
            (of_json_error_to_string err
            ^ "\n\tin object at key '"
            ^ key
            ^ "'")
      in
      Js.Dict.set target key value
    done;
    target)
  else of_json_error ~json "expected object as dict"

let result ok_of_json err_of_json (json : t) : (_, _) result =
  if Js.Array.isArray json then
    let array = (Obj.magic json : Js.Json.t array) in
    let len = Js.Array.length array in
    if Stdlib.( > ) len 0 then
      let tag = Js.Array.unsafe_get array 0 in
      if Stdlib.( = ) (Js.typeof tag) "string" then
        let tag = (Obj.magic tag : string) in
        if Stdlib.( = ) tag "Ok" then (
          if Stdlib.( <> ) len 2 then
            of_json_error ~json
              "expected result 'Ok' as array of length 2";
          Ok (ok_of_json (Js.Array.unsafe_get array 1)))
        else if Stdlib.( = ) tag "Error" then (
          if Stdlib.( <> ) len 2 then
            of_json_error ~json
              "expected result 'Error' as array of length 2";
          Error (err_of_json (Js.Array.unsafe_get array 1)))
        else
          of_json_error ~json
            "expected result as array of length 2 with values 'Ok' or \
             'Error'"
      else
        of_json_error ~json
          "expected result as non-empty array with first element being a \
           string"
    else of_json_error ~json "expected result as non-empty array"
  else of_json_error ~json "expected result as array"

let field key decode json =
  if
    Js.typeof json = "object"
    && (not (Js.Array.isArray json))
    && not ((Obj.magic json : 'a Js.null) == Js.null)
  then
    let dict = (Obj.magic (json : Js.Json.t) : Js.Json.t Js.Dict.t) in
    match Js.Dict.get dict key with
    | Some value -> (
        try decode value
        with Of_json_error err ->
          of_json_msg_error
            (of_json_error_to_string err ^ "\n\tat field '" ^ key ^ "'"))
    | None ->
        of_json_error ~json {j|expected object with field '$(key)'|j}
  else of_json_error ~json "expected object"

let rec at key_path decoder =
  match key_path with
  | [ key ] -> field key decoder
  | first :: rest -> field first (at rest decoder)
  | [] ->
      raise
      @@ Invalid_argument
           "Expected key_path to contain at least one element"

let one_of decoders json =
  let rec inner decoders errors =
    match decoders with
    | [] ->
        let formattedErrors =
          "\n- "
          ^ Js.Array.join ~sep:"\n- " (Array.of_list (List.rev errors))
        in
        of_json_msg_error
          ({j|All decoders given to oneOf failed. Here are all the errors: $formattedErrors\nAnd the JSON being decoded: |j}
          ^ Js.Json.stringify json)
    | decode :: rest -> (
        try decode json
        with Of_json_error e ->
          inner rest (of_json_error_to_string e :: errors))
  in
  inner decoders []

let either a b = one_of [ a; b ]

let try_or_none decode json =
  try Some (decode json) with Of_json_error _ -> None

let try_of_default default decode json =
  try decode json with Of_json_error _ -> default

let map f decode json = f (decode json)
