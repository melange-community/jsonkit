open Ppxlib
open Ast_builder.Default

(* All jsonschema attributes now live under [Attrs.Jsonschema]; narrow the
   file-wide [Attrs] reference to that submodule. *)
module Attrs = Attrs.Jsonschema

let deriver_name = "jsonschema"
let value_name type_name = type_name ^ "_jsonschema"
let value_name_pattern ~loc type_name = pvar ~loc (value_name type_name)
let runtime_ident ~loc name = evar ~loc ("Jsonkit_jsonschema_defs." ^ name)

(* What a schema needs from the runtime. *)
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
                (* That type's schema embeds its arguments itself. *)
                let results =
                  List.map
                    (schema_of_core_type ~config ~recursive_types
                       ~position:`Argument)
                    args
                in
                ( type_constr_conv ~loc id ~f:value_name
                    (List.map fst results),
                  List.concat_map snd results
                  @
                  match position with
                  | `Body -> [ Embedded_schema ]
                  | `Argument -> [] )))
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

let recursive_group ~loc ~path names schemas =
  let definitions targets =
    elist ~loc
      (List.map
         (fun (name, schema, _, _) ->
           [%expr [%e estring ~loc name], [%e schema]])
         (schemas targets))
  in
  let plain = List.map (fun name -> name, name) names in
  let marked =
    List.map (fun name -> name, "\000" ^ path ^ "." ^ name) names
  in
  let plain_schemas = schemas plain in
  let params =
    List.map (fun (name, _, _, params) -> name, params) plain_schemas
  in
  let group_params =
    List.sort_uniq String.compare (List.concat_map snd params)
  in
  let pattern, result =
    match names with
    | [ name ] ->
        value_name_pattern ~loc name, evar ~loc (value_name name)
    | names ->
        ( ppat_tuple ~loc (List.map (value_name_pattern ~loc) names),
          pexp_tuple ~loc
            (List.map (fun name -> evar ~loc (value_name name)) names) )
  in
  let values value =
    List.fold_right
      (fun (name, params) acc ->
        [%expr
          let [%p value_name_pattern ~loc name] =
            [%e wrap_type_params ~loc params (value name)]
          in
          [%e acc]])
      params result
  in
  if
    List.mem Embedded_schema
      (List.concat_map (fun (_, _, needs, _) -> needs) plain_schemas)
  then
    (* [ppx_defs_<first>] builds every member's schema once. *)
    let group_defs = "ppx_defs_" ^ List.hd names in
    let group =
      [%expr
        [%e runtime_ident ~loc "recursive_group"]
          ~path:[%e estring ~loc path]
          [%e
            eapply ~loc (evar ~loc group_defs)
              (List.map (evar ~loc) group_params)]]
    in
    (* Without type parameters the group is built once and shared. *)
    let member group name =
      [%expr
        [%e runtime_ident ~loc "member"] [%e estring ~loc name] [%e group]]
    in
    let values =
      match group_params with
      | [] ->
          [%expr
            let ppx_group = [%e group] in
            [%e values (member [%expr ppx_group])]]
      | _ -> values (member group)
    in
    [%stri
      let[@warning "-32-39"] [%p pattern] =
        let [%p pvar ~loc group_defs] =
          [%e wrap_type_params ~loc group_params (definitions marked)]
        in
        [%e values]]
  else
    (* Nothing to collect: a literal, keeping its inferred type. *)
    [%stri
      let[@warning "-32-39"] [%p pattern] =
        let ppx_defs = [%e definitions plain] in
        [%e
          values (fun name ->
              Schema.definitions_ref ~loc name [%expr ppx_defs])]]

let str_type_decl ~ctxt ast flag_polymorphic_variant_tuple flag_ocaml_doc
    =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  let config : Attrs.config =
    {
      Attrs.polymorphic_variant_tuple = flag_polymorphic_variant_tuple;
      Attrs.ocaml_doc = flag_ocaml_doc;
    }
  in
  match ast with
  | _, [] ->
      [%str [%ocaml.error "ppx_deriving_jsonschema: unsupported type"]]
  | rec_flag, type_decls ->
      let names = List.map (fun td -> td.ptype_name.txt) type_decls in
      (* [targets] maps each type of the group to what its refs point at. *)
      let schemas targets =
        List.map
          (fun td ->
            let name, raw, needs, params =
              schema_of_type_decl ~loc ~config ~recursive_types:targets td
            in
            let schema =
              raw
              |> Schema.Annotation.add_description ~loc
                   (Attrs.td_description ~ocaml_doc:config.Attrs.ocaml_doc
                      td)
              |> Schema.Annotation.add_annotations ~loc
                   (Attribute.get Attrs.td_attrs td)
              |> annotate_manifest ~loc td
            in
            name, schema, needs, params)
          type_decls
      in
      let plain_schemas =
        schemas
          (match rec_flag with
          | Recursive -> List.map (fun name -> name, name) names
          | Nonrecursive -> [])
      in
      if
        List.mem Group_ref
          (List.concat_map (fun (_, _, needs, _) -> needs) plain_schemas)
      then
        [
          recursive_group ~loc
            ~path:
              (Code_path.fully_qualified_path
                 (Expansion_context.Deriver.code_path ctxt))
            names schemas;
        ]
      else
        List.map
          (fun (name, schema, needs, params) ->
            create_value ~loc name
              (wrap_type_params ~loc params
                 (if List.mem Embedded_schema needs then
                    [%expr
                      [%e runtime_ident ~loc "non_recursive"] [%e schema]]
                  else schema)))
          plain_schemas

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
