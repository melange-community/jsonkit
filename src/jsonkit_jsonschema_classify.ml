type t =
  [ `Null
  | `String of string
  | `Float of float
  | `Int of int
  | `Bool of bool
  | `List of t list
  | `Assoc of (string * t) list ]

(* On native the schema value type [t] is already the JSON representation, so
   classify/declassify are the identity. (On Melange they convert to/from
   [Js.Json.t] — see ../../jsonschema/Ppx_deriving_jsonschema_runtime_classify.ml.) *)
let classify value = value
let declassify value = value
