[@@@deprecated
"This module is deprecated. Use Jsonkit_jsonschema instead."]

include
  module type of Jsonkit_jsonschema
    with module Primitives := Jsonkit_jsonschema.Primitives

val json_schema :
  ?id:string ->
  ?title:string ->
  ?description:string ->
  ?definitions:(string * t) list ->
  t ->
  t
