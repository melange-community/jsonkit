open Ppxlib
open Ast_builder.Default

(* All jsonschema attributes now live under [Attrs.Jsonschema]; narrow the
   file-wide [Attrs] reference to that submodule. *)
module Attrs = Attrs.Jsonschema

let deriver_name = "jsonschema"
let value_name type_name = type_name ^ "_jsonschema"
let value_name_pattern ~loc type_name = pvar ~loc (value_name type_name)

type need = Group_ref | Embedded_schema

let create_value ~loc name value =
  [%stri
    let[@warning "-32-39"] [%p value_name_pattern ~loc name] = [%e value]]

(* Wraps [body] in nested lambdas, one per type parameter.
   Parametric types like [('a, 'b) t] derive as [fun a b -> <schema>],
   so callers can pass schemas for each type variable. *)
let wrap_type_params ~loc params body =
  List.fold_right
    (fun param body ->
      [%expr fun [%p ppat_var ~loc { txt = param; loc }] -> [%e body]])
    params body

(* schema_of_core_type and schema_of_poly_variant are mutually recursive.
   All other functions only call downward and use plain let. *)
let rec schema_of_core_type ~(config : Attrs.config)
    ?(recursive_types = []) ?(compact_variants = false)
    ?(position = `Body) core_type =
  let loc = core_type.ptyp_loc in
  let schema, needs =
    match core_type with
    | [%type: int] | [%type: int32] | [%type: nativeint] ->
        [%expr int_jsonschema], []
    | [%type: int64] -> [%expr int64_jsonschema], []
    | [%type: float] -> [%expr float_jsonschema], []
    | [%type: string] | [%type: bytes] -> [%expr string_jsonschema], []
    | [%type: bool] -> [%expr bool_jsonschema], []
    | [%type: char] -> [%expr char_jsonschema], []
    | [%type: unit] -> [%expr unit_jsonschema], []
    | [%type: [%t? t] result] ->
        let expr, needs =
          schema_of_core_type ~config ~recursive_types ~position t
        in
        [%expr result_jsonschema [%e expr]], needs
    | [%type: [%t? t] option] ->
        let s, needs =
          schema_of_core_type ~config ~recursive_types ~position t
        in
        [%expr option_jsonschema [%e s]], needs
    | [%type: [%t? t] ref] ->
        schema_of_core_type ~config ~recursive_types ~position t
    | [%type: [%t? t] list] ->
        let t, needs =
          schema_of_core_type ~config ~recursive_types ~position t
        in
        [%expr list_jsonschema [%e t]], needs
    | [%type: [%t? t] array] ->
        let t, needs =
          schema_of_core_type ~config ~recursive_types ~position t
        in
        [%expr array_jsonschema [%e t]], needs
    | _ -> (
        match core_type.ptyp_desc with
        | Ptyp_var name -> (
            ( evar ~loc name,
              match position with
              | `Body -> [ Embedded_schema ]
              | `Argument -> [] ))
        | Ptyp_constr (id, args) -> (
            match id.txt with
            | Lident name when List.mem_assoc name recursive_types ->
                (* Recursive reference: emit $ref regardless of type arguments. *)
                ( Schema.type_ref ~loc (List.assoc name recursive_types),
                  [ Group_ref ] )
            | _ -> (
                let results =
                  List.map
                    (schema_of_core_type ~config ~recursive_types
                       ~position:`Argument)
                    args
                in
                let needs =
                  List.concat_map snd results
                  @
                  match position with
                  | `Body -> [ Embedded_schema ]
                  | `Argument -> []
                in
                let schema =
                  type_constr_conv ~loc id ~f:value_name
                    (List.map fst results)
                in
                let edv = evar ~loc "ppx_eds" in
                match List.mem Group_ref needs with
                | true ->
                    (* Hoist $defs from the sub-schema into the parent accumulator and strip
             resource boundary markers ($defs), leaving just the $ref. *)
                    ( [%expr
                        match [%e schema] with
                        | `Assoc ppx_pairs -> (
                            match
                              Stdlib.List.assoc_opt "$defs" ppx_pairs
                            with
                            | Some (`Assoc ppx_defs) ->
                                [%e edv] :=
                                  ![%e edv]
                                  @ Stdlib.List.filter
                                      (fun (n, _) ->
                                        not
                                          (Stdlib.List.mem_assoc n
                                             ![%e edv]))
                                      ppx_defs;
                                `Assoc
                                  (Stdlib.List.filter
                                     (fun (k, _) ->
                                       not (Stdlib.String.equal k "$defs"))
                                     ppx_pairs)
                            | _ -> `Assoc ppx_pairs)
                        | ppx_other -> ppx_other],
                      needs )
                | false ->
                    (* Non-recursive arg (or no accumulator): add a location-based $id to mark
             the resource boundary so that any internal $defs refs resolve correctly. *)
                    let unique_id =
                      estring ~loc
                        (Printf.sprintf "file://%s:%d"
                           loc.loc_start.pos_fname loc.loc_start.pos_lnum)
                    in
                    ( [%expr
                        match [%e schema] with
                        | `Assoc pairs
                          when Stdlib.List.mem_assoc "$defs" pairs ->
                            `Assoc
                              (("$id", `String [%e unique_id])
                              :: Stdlib.List.filter
                                   (fun (k, _) ->
                                     not (Stdlib.String.equal k "$id"))
                                   pairs)
                        | other -> other],
                      needs )))
        | Ptyp_tuple types ->
            let results =
              List.map
                (schema_of_core_type ~config ~recursive_types ~position)
                types
            in
            let ts = List.map fst results in
            let needs = List.concat_map snd results in
            Schema.tuple ~loc ts, needs
        | Ptyp_variant (row_fields, _, _) ->
            schema_of_poly_variant ~loc ~config ~recursive_types
              ~compact_variants ~position row_fields
        | _ ->
            let msg =
              Format.asprintf
                "ppx_deriving_jsonschema: unsupported type %a"
                Astlib.Pprintast.core_type core_type
            in
            [%expr [%ocaml.error [%e estring ~loc msg]]], [])
  in
  let schema =
    schema
    |> Schema.Annotation.add_description ~loc
         (Attrs.ct_description ~ocaml_doc:config.Attrs.ocaml_doc core_type)
    |> Schema.Annotation.add_format ~loc
         (Attrs.ct_format, core_type)
         core_type
    |> Schema.Annotation.add_maximum ~loc
         (Attrs.ct_maximum, core_type)
         core_type
    |> Schema.Annotation.add_minimum ~loc
         (Attrs.ct_minimum, core_type)
         core_type
    |> Schema.Annotation.add_annotations ~loc ~core_type
         (Attribute.get Attrs.ct_attrs core_type)
  in
  schema, needs

and schema_of_poly_variant ~loc ~(config : Attrs.config)
    ?(recursive_types = []) ?(compact_variants = false)
    ?(position = `Body) row_fields =
  let constrs, needs =
    List.fold_left
      (fun (constrs, needs) row_field ->
        let description_opt =
          Option.map
            (fun d -> d.txt)
            (Attrs.rtag_description ~ocaml_doc:config.Attrs.ocaml_doc
               row_field)
        in
        match row_field.prf_desc with
        | Rtag (name, true, []) ->
            let name =
              match
                Attribute.get Attrs.polymorphic_variant_name row_field
              with
              | Some name -> name.txt
              | None -> name.txt
            in
            `Tag (name, [], description_opt) :: constrs, needs
        | Rtag (name, false, [ typ ]) ->
            let name =
              match
                Attribute.get Attrs.polymorphic_variant_name row_field
              with
              | Some name -> name.txt
              | None -> name.txt
            in
            let raw_typs =
              match config.Attrs.polymorphic_variant_tuple with
              | true -> [ typ ]
              | false -> (
                  match typ.ptyp_desc with
                  | Ptyp_tuple tps -> tps
                  | _ -> [ typ ])
            in
            let results =
              List.map
                (schema_of_core_type ~config ~recursive_types ~position)
                raw_typs
            in
            let typs = List.map fst results in
            let typs_needs = List.concat_map snd results in
            ( `Tag (name, typs, description_opt) :: constrs,
              needs @ typs_needs )
        | Rtag (_, true, [ _ ]) | Rtag (_, _, _ :: _ :: _) ->
            Location.raise_errorf ~loc
              "ppx_deriving_jsonschema: polymorphic_variant/Rtag/&"
        | Rinherit core_type ->
            let typ, typ_needs =
              schema_of_core_type ~config ~recursive_types ~position
                core_type
            in
            `Inherit typ :: constrs, needs @ typ_needs
        | Rtag (_, false, []) -> assert false)
      ([], []) row_fields
  in
  let constrs = List.rev constrs in
  let v = Schema.variants ~loc ~compact_variants constrs in
  v, needs

let resolve_additional_properties ~loc ~allow ~disallow =
  match allow, disallow with
  | true, true ->
      Location.raise_errorf ~loc
        "ppx_deriving_jsonschema: [@jsonschema.allow_extra_fields] and \
         [@jsonschema.disallow_extra_fields] are mutually exclusive"
  | _, true -> false
  | _, false -> true

let schema_of_record ~loc ~(config : Attrs.config) ?(recursive_types = [])
    fields additional_properties =
  let fields, required, needs =
    List.fold_left
      (fun (fields, required, needs)
           ({ pld_name; pld_type; pld_loc = _loc; _ } as field) ->
        let name =
          match Attribute.get Attrs.key field with
          | Some name -> name.txt
          | None -> pld_name.txt
        in
        let drop_required =
          Attribute.has_flag Attrs.option field
          || Attribute.get Attrs.ld_default field |> Option.is_some
        in
        let type_def, field_needs =
          match Attribute.get Attrs.ref field with
          | Some def -> Schema.type_ref ~loc def.txt, []
          | None -> (
              match pld_type with
              | [%type: [%t? inner] option] ->
                  let s, r =
                    schema_of_core_type ~config ~recursive_types inner
                  in
                  [%expr option_jsonschema [%e s]], r
              | _ -> schema_of_core_type ~config ~recursive_types pld_type
              )
        in
        let type_def =
          type_def
          |> Schema.Annotation.add_description ~loc
               (Attrs.ld_description ~ocaml_doc:config.Attrs.ocaml_doc
                  field)
          |> Schema.Annotation.add_format ~loc (Attrs.ld_format, field)
               pld_type
          |> Schema.Annotation.add_maximum ~loc
               (Attrs.ld_maximum, field)
               pld_type
          |> Schema.Annotation.add_minimum ~loc
               (Attrs.ld_minimum, field)
               pld_type
          |> Schema.Annotation.add_default ~loc
               (Attrs.ld_default, field)
               pld_type
          |> Schema.Annotation.add_annotations ~loc ~core_type:pld_type
               (Attribute.get Attrs.ld_attrs field)
        in
        ( [%expr [%e estring ~loc name], [%e type_def]] :: fields,
          (if drop_required then required
           else { txt = name; loc } :: required),
          needs @ field_needs ))
      ([], [], []) fields
  in
  let required =
    List.map
      (fun { txt = name; loc } -> [%expr `String [%e estring ~loc name]])
      required
  in
  ( [%expr
      `Assoc
        [
          "type", `String "object";
          "properties", `Assoc [%e elist ~loc fields];
          "required", `List [%e elist ~loc required];
          ( "additionalProperties",
            `Bool [%e ebool ~loc additional_properties] );
        ]],
    needs )

let schema_of_variants ~loc ~(config : Attrs.config)
    ?(recursive_types = []) ?(compact_variants = false) variants =
  let variants, needs =
    List.fold_left
      (fun (variants, needs)
           ({ pcd_args; pcd_name = { txt = name; _ }; _ } as var) ->
        let name =
          match Attribute.get Attrs.variant_name var with
          | Some name -> name.txt
          | None -> name
        in
        let description_opt =
          Option.map
            (fun d -> d.txt)
            (Attrs.cd_description ~ocaml_doc:config.Attrs.ocaml_doc var)
        in
        match pcd_args with
        | Pcstr_record label_declarations ->
            let allow =
              Attribute.get Attrs.cd_allow_extra_fields var
              |> Option.is_some
            in
            let disallow =
              Attribute.get Attrs.cd_disallow_extra_fields var
              |> Option.is_some
            in
            let additional_properties =
              resolve_additional_properties ~loc:var.pcd_loc ~allow
                ~disallow
            in
            let obj_schema, obj_needs =
              schema_of_record ~loc ~config ~recursive_types
                label_declarations additional_properties
            in
            ( `Tag (name, [ obj_schema ], description_opt) :: variants,
              needs @ obj_needs )
        | Pcstr_tuple typs ->
            let results =
              List.map (schema_of_core_type ~config ~recursive_types) typs
            in
            let types = List.map fst results in
            let typs_needs = List.concat_map snd results in
            ( `Tag (name, types, description_opt) :: variants,
              needs @ typs_needs ))
      ([], []) variants
  in
  let variants = List.rev variants in
  let schema = Schema.variants ~loc ~compact_variants variants in
  schema, needs

let schema_of_type_decl ~loc ~(config : Attrs.config) ~recursive_types
    type_decl =
  let type_name = type_decl.ptype_name.txt in
  let params =
    List.map
      (fun tp -> (get_type_param_name tp).txt)
      type_decl.ptype_params
  in
  match type_decl.ptype_kind with
  | Ptype_variant variants ->
      let compact_variants =
        Attribute.has_flag Attrs.td_compact_variants type_decl
      in
      let schema, needs =
        schema_of_variants ~loc ~config ~recursive_types ~compact_variants
          variants
      in
      type_name, schema, needs, params
  | Ptype_record label_declarations ->
      let allow =
        Attribute.get Attrs.td_allow_extra_fields type_decl
        |> Option.is_some
      in
      let disallow =
        Attribute.get Attrs.td_disallow_extra_fields type_decl
        |> Option.is_some
      in
      let additional_properties =
        resolve_additional_properties ~loc:type_decl.ptype_loc ~allow
          ~disallow
      in
      let schema, needs =
        schema_of_record ~loc ~config ~recursive_types label_declarations
          additional_properties
      in
      type_name, schema, needs, params
  | Ptype_abstract -> (
      match type_decl.ptype_manifest with
      | Some core_type ->
          let compact_variants =
            Attribute.has_flag Attrs.td_compact_variants type_decl
          in
          let schema, needs =
            schema_of_core_type ~config ~recursive_types ~compact_variants
              core_type
          in
          type_name, schema, needs, params
      | None ->
          let msg =
            "ppx_deriving_jsonschema: abstract type without manifest"
          in
          ( type_name,
            [%expr [%ocaml.error [%e estring ~loc msg]]],
            [],
            params ))
  | Ptype_open ->
      let msg = "ppx_deriving_jsonschema: open types not supported" in
      type_name, [%expr [%ocaml.error [%e estring ~loc msg]]], [], params

let annotate_manifest ~loc type_decl schema =
  Option.fold ~none:schema
    ~some:(fun core_type ->
      Schema.Annotation.add_format ~loc
        (Attrs.td_format, type_decl)
        core_type schema
      |> Schema.Annotation.add_maximum ~loc
           (Attrs.td_maximum, type_decl)
           core_type
      |> Schema.Annotation.add_minimum ~loc
           (Attrs.td_minimum, type_decl)
           core_type)
    type_decl.ptype_manifest

let apply_defs ~loc = function
  | `Rec (primary, defs) ->
      let edv = evar ~loc "ppx_eds" in
      let vname name = "ppx_body_" ^ name in
      let pairs_expr =
        elist ~loc
          (List.map
             (fun (name, _) ->
               [%expr [%e estring ~loc name], [%e evar ~loc (vname name)]])
             defs)
      in
      let base_expr =
        Schema.definitions_ref ~loc primary
          [%expr [%e pairs_expr] @ ![%e edv]]
      in
      List.fold_right
        (fun (name, s) acc ->
          [%expr
            let [%p pvar ~loc (vname name)] = [%e s] in
            [%e acc]])
        defs base_expr
  | `NonRec schema ->
      let edv = evar ~loc "ppx_eds" in
      [%expr
        let ppx_result = [%e schema] in
        match ![%e edv] with
        | [] -> ppx_result
        | ppx_defs -> (
            match ppx_result with
            | `Assoc ppx_pairs ->
                `Assoc
                  (("$defs", `Assoc ppx_defs)
                  :: Stdlib.List.filter
                       (fun (k, _) -> not (Stdlib.String.equal k "$defs"))
                       ppx_pairs)
            | other -> other)]

let str_type_decl ~ctxt ast flag_polymorphic_variant_tuple flag_ocaml_doc
    =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  let config : Attrs.config =
    {
      Attrs.polymorphic_variant_tuple = flag_polymorphic_variant_tuple;
      Attrs.ocaml_doc = flag_ocaml_doc;
    }
  in
  let is_recursive needs = List.mem Group_ref needs in
  match ast with
  | rec_flag, [ type_decl ] ->
      let type_name = type_decl.ptype_name.txt in
      let recursive_types =
        match rec_flag with
        | Recursive -> [ type_name, type_name ]
        | Nonrecursive -> []
      in
      let _, raw_schema, needs, params =
        schema_of_type_decl ~loc ~config ~recursive_types type_decl
      in
      let raw_schema =
        raw_schema
        |> Schema.Annotation.add_description ~loc
             (Attrs.td_description ~ocaml_doc:config.Attrs.ocaml_doc
                type_decl)
        |> Schema.Annotation.add_annotations ~loc
             (Attribute.get Attrs.td_attrs type_decl)
        |> annotate_manifest ~loc type_decl
      in
      let schema =
        if is_recursive needs then
          [%expr
            let ppx_eds = ref [] in
            [%e
              apply_defs ~loc
                (`Rec (type_name, [ type_name, raw_schema ]))]]
        else
          [%expr
            let ppx_eds = ref [] in
            [%e apply_defs ~loc (`NonRec raw_schema)]]
      in
      let schema = wrap_type_params ~loc params schema in
      [ create_value ~loc type_name schema ]
  | rec_flag, type_decls when List.length type_decls > 1 ->
      let recursive_types =
        match rec_flag with
        | Recursive ->
            List.map
              (fun td -> td.ptype_name.txt, td.ptype_name.txt)
              type_decls
        | Nonrecursive -> []
      in
      let raw_results =
        List.map
          (schema_of_type_decl ~loc ~config ~recursive_types)
          type_decls
      in
      let any_recursive =
        List.exists
          (fun (_, _, needs, _) -> is_recursive needs)
          raw_results
      in
      if any_recursive then
        List.map
          (fun (name, raw, _, params) ->
            let td =
              List.find (fun td -> td.ptype_name.txt = name) type_decls
            in
            let raw =
              raw
              |> Schema.Annotation.add_description ~loc
                   (Attrs.td_description ~ocaml_doc:config.Attrs.ocaml_doc
                      td)
              |> annotate_manifest ~loc td
            in
            let defs =
              List.map
                (fun (n, r, _, _) -> n, if n = name then raw else r)
                raw_results
            in
            let schema =
              wrap_type_params ~loc params
                [%expr
                  let ppx_eds = ref [] in
                  [%e apply_defs ~loc (`Rec (name, defs))]]
            in
            create_value ~loc name schema)
          raw_results
      else
        List.map
          (fun (name, raw, _, params) ->
            let td =
              List.find (fun td -> td.ptype_name.txt = name) type_decls
            in
            let schema =
              wrap_type_params ~loc params
                [%expr
                  let ppx_eds = ref [] in
                  [%e apply_defs ~loc (`NonRec raw)]]
            in
            let schema =
              schema
              |> Schema.Annotation.add_description ~loc
                   (Attrs.td_description ~ocaml_doc:config.Attrs.ocaml_doc
                      td)
            in
            create_value ~loc name schema)
          raw_results
  | _, _ ->
      [%str [%ocaml.error "ppx_deriving_jsonschema: unsupported type"]]

let sig_type_decl ~ctxt ast _flag_polymorphic_variant_tuple
    _flag_ocaml_doc =
  let jsonschema_t ~loc =
    ptyp_constr ~loc
      { txt = Ldot (Ldot (Lident "Jsonkit", "Jsonschema"), "t"); loc }
      []
  in
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  match ast with
  | _, [ td ] ->
      let typ =
        combinator_type_of_type_declaration td ~f:(fun ~loc _core_type ->
            jsonschema_t ~loc)
      in
      let name = { txt = value_name td.ptype_name.txt; loc } in
      [
        psig_value ~loc (value_description ~loc ~name ~type_:typ ~prim:[]);
      ]
  | _, type_decls when List.length type_decls > 1 ->
      List.map
        (fun td ->
          let typ =
            combinator_type_of_type_declaration td
              ~f:(fun ~loc _core_type -> jsonschema_t ~loc)
          in
          let name = { txt = value_name td.ptype_name.txt; loc } in
          psig_value ~loc
            (value_description ~loc ~name ~type_:typ ~prim:[]))
        type_decls
  | _, _ ->
      let ext =
        Location.error_extensionf ~loc
          "ppx_deriving_jsonschema: unsupported type"
      in
      [ psig_extension ~loc ext [] ]

(* Registration is performed explicitly by the jsonkit ppx entry points
   (ppx_deriving_json_native.ml / ppx_deriving_json_js.ml) rather than at module
   load time, so the jsonschema deriver ships as part of jsonkit[-melange].ppx. *)
let register () =
  Deriving.add deriver_name
    ~str_type_decl:
      (Deriving.Generator.V2.make ~attributes:Attrs.attributes
         (Attrs.args ()) str_type_decl)
    ~sig_type_decl:
      (Deriving.Generator.V2.make ~attributes:Attrs.attributes
         (Attrs.args ()) sig_type_decl)
