(* The flat JSON API stays at the top level: the PPX emits references to
   [Jsonkit.of_json_error], [Jsonkit.t], [Jsonkit.unknown_variant_case], … *)
include Jsonkit_json
module Json = Jsonkit_json
module Jsonschema = Jsonkit_jsonschema
module Reader = Jsonkit_reader
module Writer = Jsonkit_writer

let to_json_buffer = Jsonkit_writer.json
let of_json_lexbuf = Jsonkit_reader.json

module Primitives = struct
  include Jsonschema.Primitives
  include Json.Primitives
  include Reader.Primitives
  include Writer.Primitives
end
