(** Efficient JSON handling
This module has four aspects to it:
- Parsing, which turns a JSON string into an encoded JSON data structure
- Stringification, which produces a JSON string from an encoded JSON data structure
- Encoding, which is the process of construction a JSON data structure
- Decoding, which is the process of deconstructing a JSON data structure
{3 Parsing}
{! of_string} will (try to) parse a JSON string into a JSON data structure
({! Js.Json.t}), it will raise a [Of_string_error]. There's not much more to it:
[string] in, [Js.Json.t] out.
The parsed result, and encoded JSON data structure, then needs to be decoded to
actually be usable. See {!section:Decoding} below.
{3 Stringification}
Stringification is the exact reverse of parsing. {! to_string} uses the type
system to guarantee success, but requires that the data has been encoded in a
JSON data structure first. See {!section:Encoding} below.
{3 Encoding}
Encoding creates a JSON data structure which can stringified directly with
{! to_string} or passed to other APIs requiring a typed JSON data structure. Or
you could just go straight to decoding it again, if that's your thing. Encoding
functions are in the {! To_json} module.
{3 Decoding}
Decoding is a more complex process, due to the highly dynamic nature of JSON
data structures. The {! Of_json} module provides decoder combinators that can
be combined to create complex composite decoders for any _known_ JSON data
structure. It allows for custom decoders to produce user-defined types.

@example {[
(* Parsing a JSON string using Jsonkit.of_string *)
let arrayOfInts str
  match Jsonkit.of_string str with
  | Some value ->
    match Jsonkit.Of_json.(array int value)
    | Ok arr -> arr
    | Error _ -> []
  | None -> failWith "Unable to parse JSON"

(* prints `[3, 2, 1]` *)
let _ = Js.log (arrayOfInts "[1, 2, 3]" |> Js.Array.reverse)
]}

@example {[
(* Stringifying a value using Jsonkit.to_string *)

(* prints `null` *)
let _ =
  Jsonkit.to_string (To_json.int 42)
  |> Js.log
]}

@example {[
(* Encoding a JSON data structure using Jsonkit.Encode *)

(* prints ["foo", "bar"] *)
let _ =
  [| "foo", "bar" |]
  |> Jsonkit.To_json.string_array
  |> Jsonkit.to_string
  |> Js.log

(* prints ["foo", "bar"] *)
let _ =
  [| "foo", "bar" |]
  |> Js.Array.map To_json.int
  |> To_json.json_array
  |> to_string
  |> Js.log
]}

@example {[
(* Decoding a fixed JSON data structure using Jsonkit.Of_json *)
let mapJsonObjectString f decoder encoder str =
  match Jsonkit.of_string str with
  | Ok json ->
    match Jsonkit.Of_json.(js_dict decoder json) with
    | Ok dict ->
      dict |> Js.Dict.map f
           |> Js.Dict.map encoder
           |> Jsonkit.To_json.js_dict
           |> to_string
    | Error _ -> []
  | Error _ -> []

let sum ns =
  Array.fold_left (+) 0

(* prints `{ "foo": 6, "bar": 24 }` *)
let _ =
  Js.log (
    mapJsonObjectString sum Jsonkit.Of_json.(array int) Jsonkit.To_json.int {|
      {
        "foo": [1, 2, 3],
        "bar": [9, 8, 7]
      }
    |}
  )
]}
*)

type t = Js.Json.t
(** The type of a JSON data structure *)

type json = t
(** Defined for convenience. *)

type unknown_variant_case = { tag : string; payload : t list option }
(** Standard payload-preserving record for [@json.catch_all] constructors
    on polymorphic and classic variants. Wire shapes:

    - [{ tag; payload = None }] ↔ bare JSON string ["tag"]
    - [{ tag; payload = Some [] }] ↔ JSON array [["tag"]]
    - [{ tag; payload = Some xs }] ↔ JSON array [["tag", x1, x2, …]]

    Captures any unknown-variant wire shape, lossless. *)

val unknown_variant_case_jsonschema :
  [> `Assoc of
     (string
     * [> `List of
          [> `Assoc of
             (string
             * [> `Int of int
               | `List of
                 [> `Assoc of (string * [> `String of string ]) list ]
                 list
               | `String of string ])
             list ]
          list ])
     list ]
(** JSON-schema literal for [unknown_variant_case]. The polyvariant type
    is compatible with [Ppx_deriving_jsonschema_runtime.t]: use as the
    value of [type X = ... [@@deriving jsonschema]] when the type is
    [Jsonkit.unknown_variant_case]. *)

val to_string : json -> string
(** JSON can be encoded as a string. *)

type exn +=
  | Of_string_error of string
        (** The exception raised when parsing JSON error occurs *)

val of_string : string -> json
(** JSON can be parsed from a string. Raises {Of_string_error}. *)

type 'a to_json = 'a -> json
(** Describe how to encode a value into JSON. *)

val to_json : json to_json
(** JSON can be encoded as JSON, trivially. *)

(** The type of a error which occurs during decoding JSON values. *)
type of_json_error = Json_error of string | Unexpected_variant of string

val of_json_error_to_string : of_json_error -> string
val of_json_error : ?depth:int -> ?width:int -> json:json -> string -> 'a
val of_json_msg_error : string -> 'a

val of_json_unexpected_variant :
  ?depth:int -> ?width:int -> json:json -> string -> 'a

val of_json_msg_unexpected_variant : string -> 'a

type exn +=
  | Of_json_error of of_json_error
        (** The exception raised when a decoding error occurs *)

type 'a of_json = json -> 'a
(** Describes how to decode a value out of JSON. *)

val of_json : json of_json
(** JSON can be decoded from JSON, trivially. *)

module Of_json : sig
  (** Provides a set of low level combinator primitives to decode
      Js.Json.t data structures A decoder combinator will return the
      decoded value if successful, or raise a [Of_json_error] exception if
      unsuccessful, where the string argument contains the error message.
      Decoders are designed to be combined to produce more complex
      decoders that can decode arbitrary data structures, though the
      emphasis for this library is for it to be {i possible} to decode any
      given data structure, not necessarily for it to be {i convenient}.
      For convenience you should look towards opinionated third-party
      libraries. *)

  val string : string of_json
  val char : char of_json
  val bool : bool of_json
  val int : int of_json
  val int64 : int64 of_json
  val float : float of_json
  val unit : unit of_json
  val array : 'a of_json -> 'a array of_json
  val list : 'a of_json -> 'a list of_json
  val option : 'a of_json -> 'a option of_json
  val tuple2 : 'a of_json -> 'b of_json -> ('a * 'b) of_json

  val tuple3 :
    'a of_json -> 'b of_json -> 'c of_json -> ('a * 'b * 'c) of_json

  val tuple4 :
    'a of_json ->
    'b of_json ->
    'c of_json ->
    'd of_json ->
    ('a * 'b * 'c * 'd) of_json

  val result : 'a of_json -> 'b of_json -> ('a, 'b) result of_json

  (** Auxiliary combinators *)

  val field : string -> 'a of_json -> 'a of_json
  val at : string list -> 'a of_json -> 'a of_json
  val one_of : 'a of_json list -> 'a of_json
  val either : 'a of_json -> 'a of_json -> 'a of_json
  val try_or_none : 'a of_json -> 'a option of_json
  val try_of_default : 'a -> 'a of_json -> 'a of_json
  val map : ('a -> 'b) -> 'a of_json -> 'b of_json

  (** Some JS specific combinators. *)

  val js_dict : 'a of_json -> 'a Js.Dict.t of_json
  val js_null : 'a of_json -> 'a Js.null of_json
  val js_date : Js.Date.t of_json
end

module To_json : sig
  external string : string -> json = "%identity"
  external bool : bool -> json = "%identity"
  external int : int -> json = "%identity"
  val int64 : int64 -> json
  external float : float -> json = "%identity"
  val unit : unit to_json
  val array : 'a to_json -> 'a array to_json
  val list : 'a to_json -> 'a list to_json
  val option : 'a to_json -> 'a option to_json
  val result : 'a to_json -> 'b to_json -> ('a, 'b) result to_json
  val char : char to_json
  val tuple2 : 'a to_json -> 'b to_json -> ('a * 'b) to_json

  val tuple3 :
    'a to_json -> 'b to_json -> 'c to_json -> ('a * 'b * 'c) to_json

  val tuple4 :
    'a to_json ->
    'b to_json ->
    'c to_json ->
    'd to_json ->
    ('a * 'b * 'c * 'd) to_json

  (** JS specific combinators. *)

  val js_date : Js.Date.t to_json
  val js_null : 'a to_json -> 'a Js.null to_json
  val js_dict : 'a to_json -> 'a Js.dict to_json

  (** More JS specific to_json converters which exploit JSON runtime
      representation in JS runtimes. *)

  external json_dict : json Js.dict -> json = "%identity"
  external json_array : json array -> json = "%identity"
  external string_array : string array -> json = "%identity"
  external float_array : float array -> json = "%identity"
  external int_array : int array -> json = "%identity"
  external bool_array : bool array -> json = "%identity"
end

module Primitives : sig
  val string_of_json : json -> string
  val bool_of_json : json -> bool
  val float_of_json : json -> float
  val int_of_json : json -> int
  val int64_of_json : json -> int64
  val option_of_json : (json -> 'a) -> json -> 'a option
  val unit_of_json : json -> unit

  val result_of_json :
    (json -> 'a) -> (json -> 'b) -> json -> ('a, 'b) result

  val list_of_json : (json -> 'a) -> json -> 'a list
  val array_of_json : (json -> 'a) -> json -> 'a array
  val string_to_json : string -> json
  val bool_to_json : bool -> json
  val float_to_json : float -> json
  val int_to_json : int -> json
  val int64_to_json : int64 -> json
  val option_to_json : ('a -> json) -> 'a option -> json
  val unit_to_json : unit -> json

  val result_to_json :
    ('a -> json) -> ('b -> json) -> ('a, 'b) result -> json

  val list_to_json : ('a -> json) -> 'a list -> json
  val array_to_json : ('a -> json) -> 'a array -> json
end

module Decode : sig
  type 'a decoder = 'a of_json [@@deprecated "Use `of_json` instead"]
  (** The type of a decoder combinator *)

  val id : t of_json [@@deprecated "Use `of_json` instead"]
  val bool : bool of_json [@@deprecated "Use `Of_json.bool` instead"]
  val float : float of_json [@@deprecated "Use `Of_json.float` instead"]
  val int : int of_json [@@deprecated "Use `Of_json.int` instead"]

  val string : string of_json
  [@@deprecated "Use `Of_json.string` instead"]

  val char : char of_json [@@deprecated "Use `Of_json.char` instead"]

  val date : Js.Date.t of_json
  [@@deprecated "Use `Of_json.js_date` instead"]

  val nullable : 'a of_json -> 'a Js.null of_json
  [@@deprecated "Use `Of_json.js_null` instead"]

  val array : 'a of_json -> 'a array of_json
  [@@deprecated "Use `Of_json.array` instead"]

  val list : 'a of_json -> 'a list of_json
  [@@deprecated "Use `Of_json.list` instead"]

  val pair : 'a of_json -> 'b of_json -> ('a * 'b) of_json
  [@@deprecated "Use `Of_json.tuple2` instead"]

  val tuple2 : 'a of_json -> 'b of_json -> ('a * 'b) of_json
  [@@deprecated "Use `Of_json.tuple2` instead"]

  val tuple3 :
    'a of_json -> 'b of_json -> 'c of_json -> ('a * 'b * 'c) of_json
  [@@deprecated "Use `Of_json.tuple3` instead"]

  val tuple4 :
    ('a of_json ->
     'b of_json ->
     'c of_json ->
     'd of_json ->
     ('a * 'b * 'c * 'd) of_json
    [@deprecated "Use `Of_json.tuple4` instead"])

  val dict : 'a of_json -> 'a Js.Dict.t of_json
  [@@deprecated "Use `Of_json.js_dict` instead"]

  val field : string -> 'a of_json -> 'a of_json
  [@@deprecated "Use `Of_json.field` instead"]

  val at : string list -> 'a of_json -> 'a of_json
  [@@deprecated "Use `Of_json.at` instead"]

  val optional : 'a of_json -> 'a option of_json
  [@@deprecated "Use `Of_json.try_or_none instead"]

  val oneOf : 'a of_json list -> 'a of_json
  [@@deprecated "Use `Of_json.one_of` instead"]

  val either : 'a of_json -> 'a of_json -> 'a of_json
  [@@deprecated "Use `Of_json.either` instead"]

  val withDefault : 'a -> 'a of_json -> 'a of_json
  [@@deprecated "Use `Of_json.try_of_default` instead"]

  val map : ('a -> 'b) -> 'a of_json -> 'b of_json
  [@@deprecated "Use `Of_json.map` instead"]

  val andThen : ('a -> 'b of_json) -> 'a of_json -> 'b of_json
  [@@deprecated "Use `Of_json.map` instead"]

  val nullAs : 'a -> 'a of_json
  [@@deprecated "Use `Of_json.option f |> Option.value ~default` instead"]
end
[@@deprecated "Use `Of_json` instead"]

module Encode : sig
  type 'a encoder = 'a to_json [@@deprecated "Use `to_json` instead"]

  external null : t = "null" [@@deprecated "Use `Js.Json.null` instead"]

  val string : string to_json
  [@@deprecated "Use `To_json.string` instead"]

  val float : float to_json [@@deprecated "Use `To_json.float` instead"]
  val int : int to_json [@@deprecated "Use `To_json.int` instead"]
  val bool : bool to_json [@@deprecated "Use `To_json.bool` instead"]
  val char : char to_json [@@deprecated "Use `To_json.char instead"]

  val date : Js.Date.t to_json
  [@@deprecated "Use `To_json.js_date` instead"]

  val nullable : 'a to_json -> 'a option to_json
  [@@deprecated "Use `To_json.option instead"]

  val withDefault : Js.Json.t -> 'a to_json -> 'a option -> Js.Json.t
  [@@deprecated "Use `To_json.option` instead"]

  val pair : 'a to_json -> 'b to_json -> ('a * 'b) to_json
  [@@deprecated "Use `To_json.tuple2` instead"]

  val tuple2 : 'a to_json -> 'b to_json -> ('a * 'b) to_json
  [@@deprecated "Use `To_json.tuple2` instead"]

  val tuple3 :
    'a to_json -> 'b to_json -> 'c to_json -> ('a * 'b * 'c) to_json
  [@@deprecated "Use `To_json.tuple3` instead"]

  val tuple4 :
    'a to_json ->
    'b to_json ->
    'c to_json ->
    'd to_json ->
    ('a * 'b * 'c * 'd) to_json
  [@@deprecated "Use `To_json.tuple4` instead"]

  val dict : 'a to_json -> 'a Js.Dict.t to_json
  [@@deprecated "Use `To_json.js_dict` instead"]

  val object_ : (string * Js.Json.t) list -> Js.Json.t
  [@@deprecated "Use 'To_json.json_dict (Js.Dict.fromList x)' instead"]

  val array : 'a to_json -> 'a array to_json
  [@@deprecated "Use `To_json.array` instead"]

  val list : 'a to_json -> 'a list to_json
  [@@deprecated "Use `To_json.list` instead"]

  val jsonDict : t Js.Dict.t to_json
  [@@deprecated "Use `To_json.json_dict` instead"]

  val jsonArray : t array to_json
  [@@deprecated "Use `To_json.json_array` instead"]

  val stringArray : string array to_json
  [@@deprecated "Use `To_json.string_array` instead"]

  val numberArray : float array to_json
  [@@deprecated "Use `To_json.number_array` instead"]

  val boolArray : bool array to_json
  [@@deprecated "Use `To_json.bool_array` instead"]
end
[@@deprecated "Use `To_json` instead"]

type exn += ParseError of string
  [@@deprecated "Use `Of_string_error` instead"]

val parse : string -> json option [@@deprecated "Use `of_string` instead"]
val parseOrRaise : string -> json [@@deprecated "Use `of_string` instead"]
val stringify : json -> string [@@deprecated "Use `to_string` instead"]

val classify :
  json ->
  [ `Assoc of (string * json) list
  | `Bool of bool
  | `Float of float
  | `Int of int
  | `List of json list
  | `Null
  | `String of string ]
(** Classify a JSON value into a variant type. *)

val declassify :
  [ `Assoc of (string * json) list
  | `Bool of bool
  | `Float of float
  | `Int of int
  | `List of json list
  | `Null
  | `String of string ] ->
  json
(** Declassify a variant type into a JSON value. *)

val equal : json -> json -> bool
