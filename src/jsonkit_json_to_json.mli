type json := Js.Json.t
type 'a to_json := 'a -> json

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
