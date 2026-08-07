let () =
  print_endline
    (Yojson.Basic.pretty_to_string
       (Generate_schemas_cases.snapshot
         : Jsonkit.Jsonschema.t
         :> Yojson.Basic.t))
