(* The flat JSON API stays at the top level: the PPX emits references to
   [Jsonkit.of_json_error], [Jsonkit.t], [Jsonkit.unknown_variant_case], … *)
include Jsonkit_json
module Json = Jsonkit_json
module Jsonschema = Jsonkit_jsonschema

module Primitives = struct
  include Jsonschema.Primitives
  include Json.Primitives
end
