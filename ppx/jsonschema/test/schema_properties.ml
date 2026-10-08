(* Properties every schema of the shared cases has once [make] is done:
   - flat: no [$defs] but the root's, outside resources with an [$id];
   - closed: every [#/$defs/...] ref names a root definition;
   - unique: no definition name twice;
   - normal: no definition twice under one name and its [_n] variants;
   - idempotent: [make] of the result gives the result back.
   And one about meaning, on derived schemas as they come out of the deriver
   and on every schema made of two of the above side by side:
   - faithful: unfolding the refs (a few levels deep) gives the same tree
     before [make], where nested [$defs] are scopes, and after it. *)

let defs_prefix = "#/$defs/"

let field name : Jsonkit.Jsonschema.t -> Jsonkit.Jsonschema.t option =
  function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let root_defs schema =
  match field "$defs" schema with Some (`Assoc defs) -> defs | _ -> []

(* Folds [f] over every value below [schema], skipping resources with an
   [$id] other than the root. *)
let rec fold f acc ~root (schema : Jsonkit.Jsonschema.t) =
  match schema with
  | `Assoc fields when (not root) && List.mem_assoc "$id" fields -> acc
  | `Assoc fields ->
      List.fold_left
        (fun acc (key, value) ->
          fold f (f acc key value) ~root:false value)
        acc fields
  | `List values -> List.fold_left (fold f ~root:false) acc values
  | `Null | `Bool _ | `Int _ | `Float _ | `String _ -> acc

let nested_defs schema =
  let count =
    fold (fun n key _ -> if key = "$defs" then n + 1 else n) 0
  in
  count ~root:true schema
  - Option.fold ~none:0 ~some:(fun _ -> 1) (field "$defs" schema)

let ref_names schema =
  fold
    (fun names key value ->
      match key, value with
      | "$ref", `String ref
        when String.length ref > String.length defs_prefix
             && String.sub ref 0 (String.length defs_prefix) = defs_prefix
        ->
          String.sub ref
            (String.length defs_prefix)
            (String.length ref - String.length defs_prefix)
          :: names
      | _ -> names)
    [] ~root:true schema

(* [t_2] -> [t]. *)
let base name =
  match String.rindex_opt name '_' with
  | Some i
    when i + 1 < String.length name
         && String.for_all
              (fun c -> c >= '0' && c <= '9')
              (String.sub name (i + 1) (String.length name - i - 1)) ->
      String.sub name 0 i
  | _ -> name

let without_schema_keys : Jsonkit.Jsonschema.t -> Jsonkit.Jsonschema.t =
  function
  | `Assoc fields ->
      `Assoc (List.filter (fun (key, _) -> key <> "$schema") fields)
  | other -> other

(* [schema] with each [#/$defs/...] ref replaced by what it points at,
   [depth] levels deep. [scopes] are the [$defs] around [schema], innermost
   first; a definition is unfolded in the scopes around it. *)
let rec unfold depth scopes (schema : Jsonkit.Jsonschema.t) :
    Jsonkit.Jsonschema.t =
  match schema with
  (* A resource with an [$id] is its own root: its refs resolve in its own
     [$defs] only. Ids are left out: what is compared is meaning. *)
  | `Assoc fields when List.mem_assoc "$id" fields ->
      unfold depth [] (`Assoc (List.remove_assoc "$id" fields))
  | `Assoc fields ->
      let scopes =
        match List.assoc_opt "$defs" fields with
        | Some (`Assoc defs) -> defs :: scopes
        | _ -> scopes
      in
      let rec lookup name = function
        | [] -> None
        | scope :: outer as scopes ->
            Option.fold ~none:(lookup name outer)
              ~some:(fun body -> Some (body, scopes))
              (List.assoc_opt name scope)
      in
      `Assoc
        (List.filter_map
           (function
             | "$defs", _ -> None
             | "$ref", `String ref
               when String.length ref > String.length defs_prefix
                    && String.sub ref 0 (String.length defs_prefix)
                       = defs_prefix ->
                 let name =
                   String.sub ref
                     (String.length defs_prefix)
                     (String.length ref - String.length defs_prefix)
                 in
                 Some
                   (if depth = 0 then
                      (* Names may differ once [make] renames: past the depth,
                         only that there is a ref counts. *)
                      "$ref", `String "..."
                    else
                      ( "$ref",
                        Option.fold
                          ~none:(`String ("free " ^ name))
                          ~some:(fun (body, scopes) ->
                            unfold (depth - 1) scopes body)
                          (lookup name scopes) ))
             | key, value -> Some (key, unfold depth scopes value))
           fields)
  | `List values -> `List (List.map (unfold depth scopes) values)
  | `Null | `Bool _ | `Int _ | `Float _ | `String _ -> schema

let () =
  let failures = ref 0 in
  let fail index property =
    incr failures;
    Printf.printf "schema %d: not %s\n" index property
  in
  List.iteri
    (fun index schema ->
      let defs = root_defs schema in
      let names = List.map fst defs in
      if nested_defs schema <> 0 then fail index "flat";
      if
        not
          (List.for_all
             (fun name -> List.mem name names)
             (ref_names schema))
      then fail index "closed";
      if List.length (List.sort_uniq compare names) <> List.length names
      then fail index "unique";
      if
        List.exists
          (fun (name, body) ->
            List.exists
              (fun (other, other_body) ->
                other <> name
                && base other = base name
                && other_body = body)
              defs)
          defs
      then fail index "normal";
      if
        Option.is_none (field "$id" schema)
        && without_schema_keys (Jsonkit.Jsonschema.make schema)
           <> without_schema_keys schema
      then fail index "idempotent")
    Generate_schemas_cases.schemas;
  List.iteri
    (fun index derived ->
      if
        unfold 3 [] derived
        <> unfold 3 []
             (without_schema_keys (Jsonkit.Jsonschema.make derived))
      then fail index "faithful to the derived schema")
    (Cases.
       [
         tree_jsonschema;
         foo_jsonschema;
         expr_jsonschema;
         node_a_jsonschema;
         outer_rec_jsonschema;
         same_name_jsonschema;
         same_ref_jsonschema;
         described_pair_jsonschema;
         wrapped_a_jsonschema;
         wrapped_b_jsonschema;
       ]
    @
    (* One scope nested under two scopes that define [x] differently. *)
    let nested : Jsonkit.Jsonschema.t =
      `Assoc
        [
          "$defs", `Assoc [ "y", `Assoc [ "$ref", `String "#/$defs/x" ] ];
          "$ref", `String "#/$defs/y";
        ]
    in
    let around x : Jsonkit.Jsonschema.t =
      `Assoc
        [
          "$defs", `Assoc [ "x", `Assoc [ "const", `String x ] ];
          "s", nested;
        ]
    in
    [ `Assoc [ "a", around "A"; "b", around "B" ] ]);
  let schemas = Array.of_list Generate_schemas_cases.schemas in
  Array.iteri
    (fun index left ->
      Array.iteri
        (fun other right ->
          let composed : Jsonkit.Jsonschema.t =
            `Assoc
              [ "properties", `Assoc [ "left", left; "right", right ] ]
          in
          if
            other > index
            && unfold 3 [] composed
               <> unfold 3 []
                    (without_schema_keys
                       (Jsonkit.Jsonschema.make composed))
          then fail index (Printf.sprintf "faithful with schema %d" other))
        schemas)
    schemas;
  Printf.printf "%d schemas checked, %d failures\n"
    (List.length Generate_schemas_cases.schemas)
    !failures;
  if !failures > 0 then exit 1
