[@@@deprecated
"This module and its library are deprecated. Install jsonkit-melange and \
 use Jsonkit.Jsonschema instead."]

include
  module type of Jsonkit.Jsonschema
    with module Primitives := Jsonkit_jsonschema_primitives.Jsonkit

val json_schema :
  ?id:string ->
  ?title:string ->
  ?description:string ->
  ?definitions:(string * t) list ->
  t ->
  t
