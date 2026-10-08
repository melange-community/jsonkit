open Ppxlib
open Ast_builder.Default
module Attrs = Attrs.Jsonschema

let deriver_name = "jsonschema"
let value_name type_name = type_name ^ "_jsonschema"
let value_name_pattern ~loc type_name = pvar ~loc (value_name type_name)
let runtime_ident ~loc name = evar ~loc ("Jsonkit_jsonschema_defs." ^ name)

let error_expr ~loc fmt =
  Format.kasprintf
    (fun msg ->
      pexp_extension ~loc
        (Location.error_extensionf ~loc "[@@@@deriving jsonschema]: %s"
           msg))
    fmt

let fail ~loc fmt =
  Location.raise_errorf ~loc ("[@@@@deriving jsonschema]: " ^^ fmt)

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

let name_of_constructor (cd : constructor_declaration) =
  match Attribute.get Attrs.variant_name cd with
  | Some name -> name.txt
  | None -> cd.pcd_name.txt

let name_of_rtag row_field ~default =
  match Attribute.get Attrs.polymorphic_variant_name row_field with
  | Some name -> name.txt
  | None -> default

let key_of_field (ld : label_declaration) =
  match Attribute.get Attrs.key ld with
  | Some key -> key.txt
  | None -> ld.pld_name.txt

let annotations_of_core_type ~(config : Attrs.config) core_type :
    Schema.Annotation.t =
  {
    description =
      Attrs.ct_description ~ocaml_doc:config.Attrs.ocaml_doc core_type;
    format = Attribute.get Attrs.ct_format core_type;
    maximum = Attribute.get Attrs.ct_maximum core_type;
    minimum = Attribute.get Attrs.ct_minimum core_type;
    default = None;
    attrs = Attribute.get Attrs.ct_attrs core_type;
  }

let annotations_of_label ~(config : Attrs.config) field :
    Schema.Annotation.t =
  {
    description =
      Attrs.ld_description ~ocaml_doc:config.Attrs.ocaml_doc field;
    format = Attribute.get Attrs.ld_format field;
    maximum = Attribute.get Attrs.ld_maximum field;
    minimum = Attribute.get Attrs.ld_minimum field;
    default = Attribute.get Attrs.ld_default field;
    attrs = Attribute.get Attrs.ld_attrs field;
  }

let annotations_of_type_decl ~(config : Attrs.config) td :
    Schema.Annotation.t =
  {
    description =
      Attrs.td_description ~ocaml_doc:config.Attrs.ocaml_doc td;
    format = Attribute.get Attrs.td_format td;
    maximum = Attribute.get Attrs.td_maximum td;
    minimum = Attribute.get Attrs.td_minimum td;
    default = None;
    attrs = Attribute.get Attrs.td_attrs td;
  }

type need = Group_ref | Embedded_schema
type schema = { expr : expression; needs : need list }

let without_needs expr = { expr; needs = [] }
let exprs_of schemas = List.map (fun s -> s.expr) schemas
let needs_of schemas = List.concat_map (fun s -> s.needs) schemas

type position = Body | Argument

type ctx = {
  config : Attrs.config;
  recursive_types : (string * string) list;
  position : position;
}

let embedded_schema_need ctx =
  match ctx.position with Body -> [ Embedded_schema ] | Argument -> []

let rec schema_of_core_type ctx ?(compact_variants = false) core_type =
  let loc = core_type.ptyp_loc in
  let schema =
    match core_type with
    | [%type: int] | [%type: int32] | [%type: nativeint] ->
        without_needs [%expr int_jsonschema]
    | [%type: int64] -> without_needs [%expr int64_jsonschema]
    | [%type: float] -> without_needs [%expr float_jsonschema]
    | [%type: string] | [%type: bytes] ->
        without_needs [%expr string_jsonschema]
    | [%type: bool] -> without_needs [%expr bool_jsonschema]
    | [%type: char] -> without_needs [%expr char_jsonschema]
    | [%type: unit] -> without_needs [%expr unit_jsonschema]
    | [%type: [%t? t] option] ->
        let s = schema_of_core_type ctx t in
        { s with expr = [%expr option_jsonschema [%e s.expr]] }
    | [%type: [%t? t] ref] -> schema_of_core_type ctx t
    | [%type: [%t? t] list] ->
        let s = schema_of_core_type ctx t in
        { s with expr = [%expr list_jsonschema [%e s.expr]] }
    | [%type: [%t? t] array] ->
        let s = schema_of_core_type ctx t in
        { s with expr = [%expr array_jsonschema [%e s.expr]] }
    | _ -> (
        match core_type.ptyp_desc with
        | Ptyp_var name ->
            { expr = evar ~loc name; needs = embedded_schema_need ctx }
        | Ptyp_constr ({ txt = Lident name; _ }, _)
          when List.mem_assoc name ctx.recursive_types ->
            {
              expr =
                Schema.type_ref ~loc (List.assoc name ctx.recursive_types);
              needs = [ Group_ref ];
            }
        | Ptyp_constr (lid, args) ->
            let args =
              List.map
                (schema_of_core_type { ctx with position = Argument })
                args
            in
            {
              expr =
                type_constr_conv ~loc lid ~f:value_name (exprs_of args);
              needs = needs_of args @ embedded_schema_need ctx;
            }
        | Ptyp_tuple types ->
            let items = List.map (schema_of_core_type ctx) types in
            {
              expr = Schema.tuple ~loc (exprs_of items);
              needs = needs_of items;
            }
        | Ptyp_variant (row_fields, _, _) ->
            schema_of_poly_variant ctx ~loc ~compact_variants row_fields
        | _ ->
            without_needs
              (error_expr ~loc "unsupported type %a"
                 Astlib.Pprintast.core_type core_type))
  in
  {
    schema with
    expr =
      Schema.Annotation.apply ~loc ~core_type
        (annotations_of_core_type ~config:ctx.config core_type)
        schema.expr;
  }

and schema_of_poly_variant ctx ~loc ~compact_variants row_fields =
  let schema_of_row_field row_field =
    let description =
      Option.map
        (fun d -> d.txt)
        (Attrs.rtag_description ~ocaml_doc:ctx.config.Attrs.ocaml_doc
           row_field)
    in
    match row_field.prf_desc with
    | Rinherit core_type ->
        let s = schema_of_core_type ctx core_type in
        `Inherit s.expr, s.needs
    | Rtag (name, has_constant_form, args) -> (
        let name = name_of_rtag row_field ~default:name.txt in
        match has_constant_form, args with
        | true, [] -> `Tag (name, [], description), []
        | false, [ typ ] ->
            let payload_types =
              match
                ctx.config.Attrs.polymorphic_variant_tuple, typ.ptyp_desc
              with
              | false, Ptyp_tuple tps -> tps
              | _ -> [ typ ]
            in
            let items =
              List.map (schema_of_core_type ctx) payload_types
            in
            `Tag (name, exprs_of items, description), needs_of items
        | false, [] -> assert false
        | true, _ :: _ | false, _ :: _ :: _ ->
            fail ~loc
              "conjunctive polymorphic variant tags (`A of x & y) are \
               not supported")
  in
  let results = List.map schema_of_row_field row_fields in
  {
    expr = Schema.variants ~loc ~compact_variants (List.map fst results);
    needs = List.concat_map snd results;
  }

let schema_of_record ctx ~loc ~additional_properties fields =
  let schema_of_field ({ pld_type; _ } as field) =
    let name = key_of_field field in
    let required =
      not
        (Attribute.has_flag Attrs.option field
        || Attribute.get Attrs.ld_default field |> Option.is_some)
    in
    let s =
      match Attribute.get Attrs.ref field with
      | Some def -> without_needs (Schema.type_ref ~loc def.txt)
      | None -> schema_of_core_type ctx pld_type
    in
    let expr =
      Schema.Annotation.apply ~loc ~core_type:pld_type
        (annotations_of_label ~config:ctx.config field)
        s.expr
    in
    name, required, { s with expr }
  in
  let fields = List.map schema_of_field fields in
  let needs = needs_of (List.map (fun (_, _, s) -> s) fields) in
  let fields = List.rev fields in
  let properties =
    List.map
      (fun (name, _, s) -> [%expr [%e estring ~loc name], [%e s.expr]])
      fields
  in
  let required =
    List.filter_map
      (fun (name, required, _) ->
        if required then Some [%expr `String [%e estring ~loc name]]
        else None)
      fields
  in
  {
    expr =
      [%expr
        `Assoc
          [
            "type", `String "object";
            "properties", `Assoc [%e elist ~loc properties];
            "required", `List [%e elist ~loc required];
            ( "additionalProperties",
              `Bool [%e ebool ~loc additional_properties] );
          ]];
    needs;
  }

let schema_of_variants ctx ~loc ~compact_variants constructors =
  let schema_of_constructor ({ pcd_args; _ } as cd) =
    let name = name_of_constructor cd in
    let description =
      Option.map
        (fun d -> d.txt)
        (Attrs.cd_description ~ocaml_doc:ctx.config.Attrs.ocaml_doc cd)
    in
    match pcd_args with
    | Pcstr_record label_declarations ->
        let s =
          schema_of_record ctx ~loc
            ~additional_properties:(Attrs.cd_allows_extra_fields cd)
            label_declarations
        in
        `Tag (name, [ s.expr ], description), s.needs
    | Pcstr_tuple typs ->
        let items = List.map (schema_of_core_type ctx) typs in
        `Tag (name, exprs_of items, description), needs_of items
  in
  let results = List.map schema_of_constructor constructors in
  {
    expr = Schema.variants ~loc ~compact_variants (List.map fst results);
    needs = List.concat_map snd results;
  }

type decl = {
  td : type_declaration;
  name : string;
  params : string list;
  body : schema;
}

let schema_of_type_decl ~loc ctx td =
  let name = td.ptype_name.txt in
  let params =
    List.map (fun tp -> (get_type_param_name tp).txt) td.ptype_params
  in
  let read_compact_variants_flag () =
    Attribute.has_flag Attrs.td_compact_variants td
  in
  let body =
    match td.ptype_kind with
    | Ptype_variant constructors ->
        schema_of_variants ctx ~loc
          ~compact_variants:(read_compact_variants_flag ())
          constructors
    | Ptype_record label_declarations ->
        schema_of_record ctx ~loc
          ~additional_properties:(Attrs.td_allows_extra_fields td)
          label_declarations
    | Ptype_abstract -> (
        match td.ptype_manifest with
        | Some core_type ->
            schema_of_core_type ctx
              ~compact_variants:(read_compact_variants_flag ())
              core_type
        | None ->
            without_needs
              (error_expr ~loc "abstract type without manifest"))
    | Ptype_open ->
        without_needs (error_expr ~loc "open types are not supported")
  in
  let expr =
    Schema.Annotation.apply ~loc ?core_type:td.ptype_manifest
      (annotations_of_type_decl ~config:ctx.config td)
      body.expr
  in
  { td; name; params; body = { body with expr } }

let recursive_group ~loc ~path names derive_with_targets =
  let definitions decls =
    elist ~loc
      (List.map
         (fun d -> [%expr [%e estring ~loc d.name], [%e d.body.expr]])
         decls)
  in
  let plain_targets = List.map (fun name -> name, name) names in
  let marked_targets =
    List.map (fun name -> name, "\000" ^ path ^ "." ^ name) names
  in
  let plain_decls = derive_with_targets plain_targets in
  let params_of_member =
    List.map (fun d -> d.name, d.params) plain_decls
  in
  let group_params =
    List.sort_uniq String.compare (List.concat_map snd params_of_member)
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
  let bind_members member_body =
    List.fold_right
      (fun (name, params) acc ->
        [%expr
          let [%p value_name_pattern ~loc name] =
            [%e wrap_type_params ~loc params (member_body name)]
          in
          [%e acc]])
      params_of_member result
  in
  let embeds_schemas =
    List.mem Embedded_schema
      (needs_of (List.map (fun d -> d.body) plain_decls))
  in
  if embeds_schemas then
    let group_defs = "ppx_defs_" ^ List.hd names in
    let group =
      [%expr
        [%e runtime_ident ~loc "recursive_group"]
          ~path:[%e estring ~loc path]
          [%e
            eapply ~loc (evar ~loc group_defs)
              (List.map (evar ~loc) group_params)]]
    in
    let member group name =
      [%expr
        [%e runtime_ident ~loc "member"] [%e estring ~loc name] [%e group]]
    in
    let values =
      match group_params with
      | [] ->
          [%expr
            let ppx_group = [%e group] in
            [%e bind_members (member [%expr ppx_group])]]
      | _ -> bind_members (member group)
    in
    [%stri
      let[@warning "-32-39"] [%p pattern] =
        let [%p pvar ~loc group_defs] =
          [%e
            wrap_type_params ~loc group_params
              (definitions (derive_with_targets marked_targets))]
        in
        [%e values]]
  else
    [%stri
      let[@warning "-32-39"] [%p pattern] =
        let ppx_defs = [%e definitions plain_decls] in
        [%e
          bind_members (fun name ->
              Schema.definitions_ref ~loc name [%expr ppx_defs])]]

let str_type_decl ~ctxt (rec_flag, type_decls)
    flag_polymorphic_variant_tuple flag_ocaml_doc =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  let config : Attrs.config =
    {
      Attrs.polymorphic_variant_tuple = flag_polymorphic_variant_tuple;
      Attrs.ocaml_doc = flag_ocaml_doc;
    }
  in
  let names = List.map (fun td -> td.ptype_name.txt) type_decls in
  let derive_with_targets recursive_types =
    let ctx = { config; recursive_types; position = Body } in
    List.map (schema_of_type_decl ~loc ctx) type_decls
  in
  let plain_decls =
    derive_with_targets
      (match rec_flag with
      | Recursive -> List.map (fun name -> name, name) names
      | Nonrecursive -> [])
  in
  let refers_to_group =
    List.mem Group_ref (needs_of (List.map (fun d -> d.body) plain_decls))
  in
  if refers_to_group then
    [
      recursive_group ~loc
        ~path:
          (Code_path.fully_qualified_path
             (Expansion_context.Deriver.code_path ctxt))
        names derive_with_targets;
    ]
  else
    List.map
      (fun d ->
        let body =
          if List.mem Embedded_schema d.body.needs then
            [%expr
              [%e runtime_ident ~loc "non_recursive"] [%e d.body.expr]]
          else d.body.expr
        in
        create_value ~loc d.name (wrap_type_params ~loc d.params body))
      plain_decls

let sig_type_decl ~ctxt (_rec_flag, type_decls)
    _flag_polymorphic_variant_tuple _flag_ocaml_doc =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  let jsonschema_t ~loc =
    ptyp_constr ~loc
      { txt = Ldot (Ldot (Lident "Jsonkit", "Jsonschema"), "t"); loc }
      []
  in
  List.map
    (fun td ->
      let typ =
        combinator_type_of_type_declaration td ~f:(fun ~loc _core_type ->
            jsonschema_t ~loc)
      in
      let name = { txt = value_name td.ptype_name.txt; loc } in
      psig_value ~loc (value_description ~loc ~name ~type_:typ ~prim:[]))
    type_decls

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
