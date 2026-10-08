(** Composes derived schemas with a single root [$defs]: the runtime of
    [[@@deriving jsonschema]] and [Jsonkit.Jsonschema.make]. *)

val non_recursive :
  Jsonkit_jsonschema_classify.t -> Jsonkit_jsonschema_classify.t
(** A non-recursive derived schema, with its root [$defs]. *)

type group

val recursive_group :
  path:string -> (string * Jsonkit_jsonschema_classify.t) list -> group
(** The recursive group [members], defined in module [path]. *)

val member : string -> group -> Jsonkit_jsonschema_classify.t
(** The schema of one member of a group. *)

val bundle :
  definitions:(string * Jsonkit_jsonschema_classify.t) list ->
  Jsonkit_jsonschema_classify.t ->
  (string * Jsonkit_jsonschema_classify.t) list
  * Jsonkit_jsonschema_classify.t
(** [definitions] and every [$defs] nested in [schema], as one list, with
    [schema] without them. *)
