type t = Direct | Via_json

let current = ref Direct
let values = [ "direct"; "yojson" ]

let set value =
  match value with
  | "direct" -> current := Direct
  | "yojson" -> current := Via_json
  | other ->
      raise
        (Arg.Bad
           (Printf.sprintf "-parser: expected %s, got %s"
              (String.concat " or " values)
              other))

let doc =
  "=direct|yojson  how a derived writer reaches the types it references: \
   direct uses their to_json_buffer, yojson goes through their to_json \
   (default: direct)"
