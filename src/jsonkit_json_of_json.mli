type json := Js.Json.t
type 'a of_json := json -> 'a

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
