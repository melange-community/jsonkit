type 'a t = Yojson.lexer_state -> Lexing.lexbuf -> 'a

val run : 'a t -> string -> 'a
val of_string : of_json:'a Jsonkit_json.of_json -> 'a t -> string -> 'a
val via_of_json : 'a Jsonkit_json.of_json -> 'a t
val json : Jsonkit_json.t t
val skip : unit t
val peek_char : char option t
val string : string t
val bool : bool t
val int : int t
val int64 : int64 t
val float : float t
val unit : unit t
val option : 'a t -> 'a option t
val list : 'a t -> 'a list t
val array : 'a t -> 'a array t
val result : 'a t -> 'b t -> ('a, 'b) result t
val array_start : unit t
val array_is_empty : bool t
val array_has_next : bool t
val array_next : unit t
val array_end : unit t
val variant : (string -> 'a t) -> 'a t
val object_fields : (string -> unit t) -> unit t
val missing_field : string -> string -> 'a

module Primitives : sig
  val string_of_json_lexbuf : string t
  val bool_of_json_lexbuf : bool t
  val int_of_json_lexbuf : int t
  val int64_of_json_lexbuf : int64 t
  val float_of_json_lexbuf : float t
  val unit_of_json_lexbuf : unit t
  val option_of_json_lexbuf : 'a t -> 'a option t
  val list_of_json_lexbuf : 'a t -> 'a list t
  val array_of_json_lexbuf : 'a t -> 'a array t
  val result_of_json_lexbuf : 'a t -> 'b t -> ('a, 'b) result t
end
