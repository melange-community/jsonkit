val schema_version : string

type t = Jsonkit_jsonschema_classify.t

val classify : t -> t
val declassify : t -> t

val make :
  ?id:string ->
  ?title:string ->
  ?description:string ->
  ?definitions:(string * t) list ->
  t ->
  t

module Classify : module type of Jsonkit_jsonschema_classify

module Primitives : module type of Jsonkit_jsonschema_primitives.Jsonkit
(** Primitive schemas matching jsonkit's own [to_json]/[of_json] encoding.
*)

module Yojson_primitives :
    module type of Jsonkit_jsonschema_primitives.Yojson
(** Primitive schemas matching yojson-style encoding, where [int64] is a
    JSON number rather than a string. *)
