type 'a t = 'a -> Buffer.t -> unit
type obj = { buffer : Buffer.t; mutable is_empty : bool }

val to_string : ?size:int -> 'a t -> 'a -> string
val via_to_json : 'a Jsonkit_json.to_json -> 'a t
val json : Jsonkit_json.t t
val string : string t
val literal : string t
val bool : bool t
val int : int t
val int64 : int64 t
val float : float t
val unit : unit t
val option : 'a t -> 'a option t
val list : 'a t -> 'a list t
val array : 'a t -> 'a array t
val result : 'a t -> 'b t -> ('a, 'b) result t
val obj : Buffer.t -> (obj -> unit) -> unit
val key : obj -> string -> Buffer.t
val key_escaped : obj -> string -> Buffer.t
val quote_key : string -> string

module Primitives : sig
  val string_to_json_buffer : string t
  val bool_to_json_buffer : bool t
  val int_to_json_buffer : int t
  val int64_to_json_buffer : int64 t
  val float_to_json_buffer : float t
  val unit_to_json_buffer : unit t
  val option_to_json_buffer : 'a t -> 'a option t
  val list_to_json_buffer : 'a t -> 'a list t
  val array_to_json_buffer : 'a t -> 'a array t
  val result_to_json_buffer : 'a t -> 'b t -> ('a, 'b) result t
end
