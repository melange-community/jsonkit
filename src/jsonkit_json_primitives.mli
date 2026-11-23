type json := Js.Json.t

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
