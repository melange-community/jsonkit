val schema_version : string

type t = Jsonkit_jsonschema_classify.t

val classify : Js.Json.t -> t
val declassify : t -> Js.Json.t

val make :
  ?id:string ->
  ?title:string ->
  ?description:string ->
  ?definitions:(string * t) list ->
  t ->
  t
(** [make ?id ?title ?description ?definitions schema] turns [schema] into
    a standalone document: it adds [$schema] and the optional metadata,
    and hoists the [$defs] of every nested derived schema (objects whose
    [$id] is absent or starts with ["file://"]) into the root [$defs],
    next to [definitions]. Identical definitions are emitted once;
    clashing names are renamed to [name_2], [name_3], ... and their
    [$ref]s rewritten. Objects with any other [$id] are separate resources
    and are left untouched. *)

module Classify : module type of Jsonkit_jsonschema_classify

module Primitives : module type of Jsonkit_jsonschema_primitives.Jsonkit
(** Primitive schemas matching jsonkit's own [to_json]/[of_json] encoding.
*)

module Yojson_primitives :
    module type of Jsonkit_jsonschema_primitives.Yojson
(** Primitive schemas matching yojson-style encoding, where [int64] is a
    JSON number rather than a string. *)
