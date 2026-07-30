open Printf

type t = Yojson.Basic.t
(** The type of a JSON data structure *)

type json = t
(** Defined for convenience. *)

type unknown_variant_case = { tag : string; payload : t list option }
(** Standard payload-preserving record for [@json.catch_all] constructors
    on polymorphic and classic variants. The PPX generates record literals
    of this shape; users can reference this type directly instead of
    defining their own. Wire shapes:

    - [{ tag; payload = None }] ↔ bare JSON string ["tag"]
    - [{ tag; payload = Some [] }] ↔ JSON array [["tag"]]
    - [{ tag; payload = Some xs }] ↔ JSON array [["tag", x1, x2, …]]

    Captures any unknown-variant wire shape, lossless. *)

(* Companion schema for ppx_deriving_jsonschema callers. Structurally
   compatible with Ppx_deriving_jsonschema_runtime.t — no library
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

let classify = Jsonkit_classify.classify
let declassify = Jsonkit_classify.declassify
let to_string t = Yojson.Basic.to_string t

include Jsonkit_errors

let of_string s =
  try Yojson.Basic.from_string s
  with Yojson.Json_error msg -> raise (Of_string_error msg)

type 'a to_json = 'a -> json
(** Describe how to encode a value into JSON. *)

let to_json : json to_json = fun x -> x

let () =
  Printexc.register_printer (function
    | Of_json_error (Json_error str) ->
        Some (sprintf "Jsonkit.Of_json_error(Json_error {|%s|})" str)
    | Of_json_error (Unexpected_variant str) ->
        Some
          (sprintf "Jsonkit.Of_json_error(Unexpected_variant {|%s|})" str)
    | _ -> None)

type 'a of_json = json -> 'a
(** Describe how to decode a value from JSON. *)

let of_json : 'a of_json = fun x -> x

module Of_json = struct
  let typeof = function
    | `Assoc _ -> "object"
    | `Bool _ -> "bool"
    | `Float _ -> "float"
    | `Int _ -> "int"
    | `List _ -> "array"
    | `Null -> "null"
    | `String _ -> "string"

  let string = function
    | `String s -> s
    | json -> of_json_error_type_mismatch json "string"

  let bool = function
    | `Bool b -> b
    | json -> of_json_error_type_mismatch json "bool"

  let int = function
    | `Int i -> i
    | json -> of_json_error_type_mismatch json "int"

  let int64 = function
    | `String i as json -> (
        match Int64.of_string_opt i with
        | Some v -> v
        | None -> of_json_error_type_mismatch json "int64 as string")
    | json -> of_json_error_type_mismatch json "int64 as string"

  let float = function
    | `Float f -> f
    | `Int i -> float_of_int i
    | json -> of_json_error_type_mismatch json "float"

  let unit = function
    | `Null -> ()
    | json -> of_json_error_type_mismatch json "expected null"

  let option v_of_json = function
    | `Null -> None
    | json -> Some (v_of_json json)

  let list v_of_json = function
    | `List l -> List.map v_of_json l
    | json -> of_json_error_type_mismatch json "array"

  let array v_of_json = function
    | `List l -> Array.map v_of_json (Array.of_list l)
    | json -> of_json_error_type_mismatch json "array"

  let result ok_of_json err_of_json json =
    match json with
    | `List [ `String "Ok"; x ] -> Ok (ok_of_json x)
    | `List [ `String "Error"; x ] -> Error (err_of_json x)
    | _ ->
        of_json_error {|expected ["Ok"; _] or ["Error"; _]|} ~depth:2
          ~json
end

module To_json = struct
  let string v = `String v
  let bool v = `Bool v
  let int v = `Int v
  let int64 v = `String (Int64.to_string v)
  let float v = `Float v
  let unit () = `Null
  let list v_to_json vs = `List (List.map v_to_json vs)
  let array v_to_json vs = `List (Array.to_list (Array.map v_to_json vs))
  let option v_to_json = function None -> `Null | Some v -> v_to_json v

  let result a_to_json b_to_json v =
    match v with
    | Ok x -> `List [ `String "Ok"; a_to_json x ]
    | Error x -> `List [ `String "Error"; b_to_json x ]
end

module Primitives = struct
  let string_of_json = Of_json.string
  let bool_of_json = Of_json.bool
  let float_of_json = Of_json.float
  let int_of_json = Of_json.int
  let int64_of_json = Of_json.int64
  let option_of_json = Of_json.option
  let unit_of_json = Of_json.unit
  let result_of_json = Of_json.result
  let list_of_json = Of_json.list
  let array_of_json = Of_json.array
  let string_to_json = To_json.string
  let bool_to_json = To_json.bool
  let float_to_json = To_json.float
  let int_to_json = To_json.int
  let int64_to_json = To_json.int64
  let option_to_json = To_json.option
  let unit_to_json = To_json.unit
  let result_to_json = To_json.result
  let list_to_json = To_json.list
  let array_to_json = To_json.array
end

let equal = Yojson.Basic.equal
