type t
type 'a reader = t -> 'a

exception Fallback

val of_string :
  ?detach_strings:bool ->
  fallback:(string -> 'a) ->
  'a reader ->
  string ->
  'a

val of_json : (Js.Json.t -> 'a) -> 'a reader
val string : string reader
val bool : bool reader
val int : int reader
val float : float reader
val int64 : int64 reader
val unit : unit reader
val option : 'a reader -> 'a option reader
val list : 'a reader -> 'a list reader
val array : 'a reader -> 'a array reader
val result : 'a reader -> 'b reader -> ('a, 'b) result reader
val fallback : unit -> 'a
val lit : t -> string -> bool
val char : t -> int -> unit
val null : t -> bool
val skip : t -> unit
val position : t -> int
val speculating : t -> bool
val stop_speculating : t -> int -> unit
val object_start : t -> bool
val member_start : t -> int
val skip_member : t -> unit
val more_members : t -> bool
val array_start : t -> bool
val more_items : t -> bool
val push : 'a array -> 'a -> unit
val absent : Obj.t
