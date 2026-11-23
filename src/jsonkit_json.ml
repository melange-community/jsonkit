type t = Js.Json.t
type json = t
type unknown_variant_case = { tag : string; payload : t list option }

(* Schema literal for [unknown_variant_case]: polyvariant constructors
   are compatible with Jsonkit.Jsonschema.t — no library
   dependency added; the polyvariant literal unifies with the runtime
   type at the use site. The schema is "oneOf string / non-empty array
   of any" — the two wire shapes a catch-all constructor can take. *)
let unknown_variant_case_jsonschema =
  `Assoc
    [
      ( "oneOf",
        `List
          [
            `Assoc [ "type", `String "string" ];
            `Assoc
              [
                "type", `String "array";
                "minItems", `Int 1;
                "items", `List [ `Assoc [ "type", `String "string" ] ];
              ];
          ] );
    ]

let classify = Jsonkit_json_classify.classify
let declassify = Jsonkit_json_classify.declassify
let to_json t = t
let of_json t = t

type 'a of_json = Js.Json.t -> 'a
type 'a to_json = 'a -> Js.Json.t

include Jsonkit_json_errors

let to_string t = Js.Json.stringify t

let of_string s =
  try Js.Json.parseExn s
  with exn ->
    let msg =
      match Js.Exn.asJsExn exn with
      | Some jsexn -> Js.Exn.message jsexn
      | None -> None
    in
    let msg =
      (* msg really cannot be None in browser or any sane JS runtime *)
      Option.value msg ~default:"JSON error"
    in
    raise (Of_string_error msg)

module Of_json = Jsonkit_json_of_json
module To_json = Jsonkit_json_to_json
module Primitives = Jsonkit_json_primitives

module Decode = struct
  type 'a decoder = 'a of_json

  let id json = json
  let bool = Of_json.bool
  let float = Of_json.float
  let int = Of_json.int
  let string = Of_json.string
  let char = Of_json.char
  let date json = Of_json.js_date json
  let nullable = Of_json.js_null
  let array = Of_json.array
  let list = Of_json.list
  let pair = Of_json.tuple2
  let tuple2 = Of_json.tuple2
  let tuple3 = Of_json.tuple3
  let tuple4 = Of_json.tuple4
  let dict = Of_json.js_dict
  let field = Of_json.field
  let at = Of_json.at
  let optional = Of_json.try_or_none
  let withDefault = Of_json.try_of_default
  let oneOf = Of_json.one_of
  let either = Of_json.either
  let map = Of_json.map
  let andThen b a json = b (a json) json

  let nullAs value json =
    if (Obj.magic json : 'a Js.null) == Js.null then value
    else of_json_error ~json "expected null"
end

module Encode = struct
  type 'a encoder = 'a to_json

  external null : t = "null"

  let string = To_json.string
  let float = To_json.float
  let int = To_json.int
  let bool = To_json.bool
  let char = To_json.char
  let date = To_json.js_date
  let list = To_json.list
  let array = To_json.array
  let nullable = To_json.option
  let withDefault d encode = function None -> d | Some v -> encode v
  let jsonDict = To_json.json_dict
  let dict = To_json.js_dict
  let object_ props = To_json.json_dict (Js.Dict.fromList props)
  let jsonArray = To_json.json_array
  let pair = To_json.tuple2
  let tuple2 = To_json.tuple2
  let tuple3 = To_json.tuple3
  let tuple4 = To_json.tuple4
  let stringArray = To_json.string_array
  let numberArray = To_json.float_array
  let boolArray = To_json.bool_array
end

exception ParseError = Of_string_error

let parse s = try Some (Js.Json.parseExn s) with _ -> None

let parseOrRaise s =
  try Js.Json.parseExn s
  with Js.Exn.Error e ->
    let message =
      match Js.Exn.message e with Some m -> m | None -> "Unknown error"
    in
    raise @@ ParseError message

external stringify : Js.Json.t -> string = "JSON.stringify"

let rec equal (a : Js.Json.t) (b : Js.Json.t) : bool =
  if (Obj.magic a : 'a Js.null) == Js.null then
    (Obj.magic b : 'a Js.null) == Js.null
  else if (Obj.magic b : 'a Js.null) == Js.null then false
  else
    let ta = Js.typeof a in
    if ta <> Js.typeof b then false
    else if ta = "string" then
      (Obj.magic a : string) = (Obj.magic b : string)
    else if ta = "number" then
      (Obj.magic a : float) = (Obj.magic b : float)
    else if ta = "boolean" then
      (Obj.magic a : bool) = (Obj.magic b : bool)
    else
      (* could be array or object *)
      let a_is_array = Js.Array.isArray a in
      if a_is_array <> Js.Array.isArray b then false
      else if a_is_array then
        let a = (Obj.magic a : Js.Json.t array) in
        let b = (Obj.magic b : Js.Json.t array) in
        let len = Js.Array.length a in
        len = Js.Array.length b
        && begin
          let rec loop i =
            i >= len
            || equal (Array.unsafe_get a i) (Array.unsafe_get b i)
               && loop (i + 1)
          in
          loop 0
        end
      else
        let a = (Obj.magic a : Js.Json.t Js.Dict.t) in
        let b = (Obj.magic b : Js.Json.t Js.Dict.t) in
        let ka = Js.Dict.keys a in
        let kb = Js.Dict.keys b in
        Js.Array.length ka = Js.Array.length kb
        && begin
          let rec loop i =
            if i >= Js.Array.length ka then true
            else
              let key = Array.unsafe_get ka i in
              match Js.Dict.get b key with
              | None -> false
              | Some vb ->
                  equal (Js.Dict.unsafeGet a key) vb && loop (i + 1)
          in
          loop 0
        end
