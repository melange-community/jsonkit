open Jsonkit.Jsonschema.Yojson_primitives

type yojson_record = {
  big : int64;
  maybe : int option;
  nothing : unit;
  items : string list;
}
[@@deriving jsonschema]
