let () =
  print_endline
    (Yojson.Basic.pretty_to_string
       (Generate_schemas_cases.snapshot
         : Jsonkit_jsonschema.t
         :> Yojson.Basic.t))
