let () =
  print_endline
    (Yojson.Safe.pretty_to_string
       (Generate_schemas_cases.snapshot
         : Jsonkit.Jsonschema.t
         :> Yojson.Safe.t))
