open Ppxlib

(* Attributes shared by the [json] and [jsonschema] derivers. [Common] declares
   each one under the instantiating deriver's namespace (e.g. [@json.key] /
   [@jsonschema.key]) so ppxlib attributes the payload to the right deriver. *)
module Common (A : sig
  val deriver : string
end) =
struct
  let deriver = A.deriver

  let string_attr name ctx =
    Attribute.declare name ctx
      Ast_pattern.(single_expr_payload (estring __'))
      (fun x -> x)

  let expr_attr name ctx =
    Attribute.declare name ctx
      Ast_pattern.(single_expr_payload __)
      (fun x -> x)

  let record_key =
    string_attr
      (Printf.sprintf "%s.key" deriver)
      Attribute.Context.label_declaration

  let variant_name =
    string_attr
      (Printf.sprintf "%s.name" deriver)
      Attribute.Context.constructor_declaration

  let polymorphic_variant_name =
    string_attr (Printf.sprintf "%s.name" deriver) Attribute.Context.rtag

  let td_allow_extra_fields =
    Attribute.declare
      (Printf.sprintf "%s.allow_extra_fields" deriver)
      Attribute.Context.type_declaration
      Ast_pattern.(pstr nil)
      ()

  let cd_allow_extra_fields =
    Attribute.declare
      (Printf.sprintf "%s.allow_extra_fields" deriver)
      Attribute.Context.constructor_declaration
      Ast_pattern.(pstr nil)
      ()

  let td_disallow_extra_fields =
    Attribute.declare
      (Printf.sprintf "%s.disallow_extra_fields" deriver)
      Attribute.Context.type_declaration
      Ast_pattern.(pstr nil)
      ()

  let cd_disallow_extra_fields =
    Attribute.declare
      (Printf.sprintf "%s.disallow_extra_fields" deriver)
      Attribute.Context.constructor_declaration
      Ast_pattern.(pstr nil)
      ()

  let record_value_option =
    Attribute.declare_flag
      (Printf.sprintf "%s.option" deriver)
      Attribute.Context.label_declaration

  let ld_default =
    expr_attr
      (Printf.sprintf "%s.default" deriver)
      Attribute.Context.label_declaration

  let td_compact_variants =
    Attribute.declare_flag
      (Printf.sprintf "%s.compact_variants" deriver)
      Attribute.Context.type_declaration

  (* All shared attributes, spliced into each deriver's own [attributes] list
       so ppxlib knows the deriver legitimately consumes them. *)
  let attributes =
    [
      Attribute.T record_key;
      Attribute.T variant_name;
      Attribute.T polymorphic_variant_name;
      Attribute.T td_allow_extra_fields;
      Attribute.T cd_allow_extra_fields;
      Attribute.T td_disallow_extra_fields;
      Attribute.T cd_disallow_extra_fields;
      Attribute.T record_value_option;
      Attribute.T ld_default;
      Attribute.T td_compact_variants;
    ]
end

module Json = struct
  open StdLabels
  open Ast_builder.Default

  (* Attributes shared with the [jsonschema] deriver: [@json.key], [@json.name],
     [@json.allow_extra_fields] / [@json.disallow_extra_fields], [@json.option],
     [@json.default] and [@@json.compact_variants]. *)
  include Common (struct
    let deriver = "json"
  end)

  (* A variant case as seen by the attribute readers: either a regular variant
     constructor or a polymorphic-variant tag. *)
  type case_ctx =
    [ `Variant_ctx of constructor_declaration
    | `Polyvariant_ctx of row_field ]

  (* Read an attribute off a variant case regardless of whether it is a regular
     variant constructor or a polymorphic-variant tag, dispatching on the source
     node to the appropriately-typed attribute declaration. *)
  let get_of_variant_case ?mark_as_seen ~variant ~polyvariant = function
    | `Variant_ctx ctx -> Attribute.get ?mark_as_seen variant ctx
    | `Polyvariant_ctx ctx -> Attribute.get ?mark_as_seen polyvariant ctx

  (* [@json.name "..."] on a variant constructor / polymorphic-variant tag. *)
  let attr_json_name_cd = variant_name
  let attr_json_name_rtag = polymorphic_variant_name

  let vcs_attr_json_name =
    get_of_variant_case ~variant:attr_json_name_cd
      ~polyvariant:attr_json_name_rtag

  (* [@@json.compact_variants] on a type declaration. *)
  let is_compact_variants td =
    Option.is_some (Attribute.get td_compact_variants td)

  (* [@json.allow_any] flag on a variant constructor / polymorphic-variant tag. *)
  let allow_any_cd =
    Attribute.declare_flag "json.allow_any"
      Attribute.Context.constructor_declaration

  let allow_any_rtag =
    Attribute.declare_flag "json.allow_any" Attribute.Context.rtag

  let vcs_attr_json_allow_any ?mark_as_seen ctx =
    match
      get_of_variant_case ~variant:allow_any_cd
        ~polyvariant:allow_any_rtag ?mark_as_seen ctx
    with
    | None -> false
    | Some () -> true

  (* [@json.catch_all] marks a variant constructor as the catch-all for any
     unrecognised string tag. The decoder routes both bare unknown strings and
     unknown array variants ["future_tag", ...] to this constructor (in the
     array case any payload is captured into the [payload] field for lossless
     round-trip). The encoder writes the value back in the same wire shape.
     Pairs naturally with [@@json.compact_variants] so the known cases are
     also bare strings. *)
  let catch_all_cd =
    Attribute.declare_flag "json.catch_all"
      Attribute.Context.constructor_declaration

  let catch_all_rtag =
    Attribute.declare_flag "json.catch_all" Attribute.Context.rtag

  let vcs_attr_json_catch_all ?mark_as_seen ctx =
    match
      get_of_variant_case ~variant:catch_all_cd
        ~polyvariant:catch_all_rtag ?mark_as_seen ctx
    with
    | None -> false
    | Some () -> true

  (* [@json.key "..."] on a record field. *)
  let ld_attr_json_key = Attribute.get record_key

  (* [@json.option] on a record field. *)
  let ld_attr_json_option = Attribute.get record_value_option

  (* [@@json.allow_extra_fields] / [@json.allow_extra_fields] and their
     [@@json.disallow_extra_fields] / [@json.disallow_extra_fields] counterparts.
     [td_allow_extra_fields] / [cd_allow_extra_fields] resolve the pair into a
     single policy (extra fields are permitted unless explicitly disallowed). *)
  let resolve_allow_extra_fields ~loc allow disallow =
    match allow, disallow with
    | Some (), Some () ->
        Location.raise_errorf ~loc
          "[@json.allow_extra_fields] and [@json.disallow_extra_fields] \
           are mutually exclusive"
    | _, Some () -> false
    | _ -> true

  let td_allow_extra_fields (td : type_declaration) =
    resolve_allow_extra_fields ~loc:td.ptype_loc
      (Attribute.get td_allow_extra_fields td)
      (Attribute.get td_disallow_extra_fields td)

  let cd_allow_extra_fields (cd : constructor_declaration) =
    resolve_allow_extra_fields ~loc:cd.pcd_loc
      (Attribute.get cd_allow_extra_fields cd)
      (Attribute.get cd_disallow_extra_fields cd)

  (* [@json.default expr] on a record field. [ld_attr_default] also treats a
     [@json.option] field as defaulting to [None]. *)
  let ld_attr_json_default = Attribute.get ld_default

  let ld_attr_default ld =
    match ld_attr_json_default ld with
    | Some e -> Some e
    | None -> (
        match ld_attr_json_option ld with
        | Some () ->
            let loc = ld.pld_loc in
            Some [%expr Stdlib.Option.None]
        | None -> None)

  (* [@json.drop_default] (flag) or [@json.drop_default f] (comparison fn), and
     [@json.drop_default_if_json_equal]. [ld_drop_default] resolves the whole
     family (together with [@option]/[@default]) into the drop policy to apply. *)
  let json_drop_default =
    Attribute.declare "json.drop_default"
      Attribute.Context.label_declaration
      Ast_pattern.(
        pstr (map0 ~f:None nil) (* flag form *)
        ||| single_expr_payload (map1 ~f:Option.some __)
        (* comparison function *))
      (fun x -> x)

  let ld_attr_json_drop_default = Attribute.get json_drop_default

  let json_drop_default_if_json_equal =
    Attribute.declare_flag "json.drop_default_if_json_equal"
      Attribute.Context.label_declaration

  let ld_attr_json_drop_default_if_json_equal =
    Attribute.get json_drop_default_if_json_equal

  let equal_affix = Expansion_helpers.Prefix "equal"

  let rec equal_of_core_type ~loc ct =
    match ct.ptyp_desc with
    | Ptyp_constr (lid, args) ->
        let fn =
          pexp_ident ~loc
            {
              loc;
              txt = Expansion_helpers.mangle_lid equal_affix lid.txt;
            }
        in
        List.fold_left (List.rev args) ~init:fn ~f:(fun acc arg ->
            pexp_apply ~loc acc [ Nolabel, equal_of_core_type ~loc arg ])
    | Ptyp_var name ->
        evar ~loc (Expansion_helpers.mangle equal_affix name)
    | _ ->
        Location.raise_errorf ~loc
          "[@drop_default]: cannot derive equal for this type, provide a \
           comparison function via [@drop_default f]"

  let ld_drop_default ld =
    let loc = ld.pld_loc in
    let drop_default = ld_attr_json_drop_default ld in
    let drop_json_equal = ld_attr_json_drop_default_if_json_equal ld in
    match drop_default, drop_json_equal with
    | Some _, Some () ->
        Location.raise_errorf ~loc
          "[@drop_default] and [@drop_default_if_json_equal] are \
           mutually exclusive"
    | None, None -> `No
    | None, Some () -> begin
        match ld_attr_json_option ld, ld_attr_json_default ld with
        | None, Some def -> `Drop_default_if_json_equal def
        | Some (), None ->
            Location.raise_errorf ~loc
              "[@drop_default_if_json_equal] cannot be used with \
               [@option]. Use [@drop_default] instead."
        | Some (), Some _ ->
            Location.raise_errorf ~loc
              "[@drop_default_if_json_equal] cannot be used with both \
               [@option] and [@default]. Use [@json.default] only."
        | None, None ->
            Location.raise_errorf ~loc
              "[@drop_default_if_json_equal] requires [@json.default]"
      end
    | Some None, None -> begin
        (* flag form: [@json.drop_default] *)
        match ld_attr_json_option ld, ld_attr_json_default ld with
        | Some (), None -> `Drop_option
        | None, Some def ->
            let cmp = equal_of_core_type ~loc ld.pld_type in
            `Drop_default (cmp, def)
        | Some (), Some _ ->
            Location.raise_errorf ~loc
              "[@drop_default] cannot be used with both [@option] and \
               [@default]"
        | None, None ->
            Location.raise_errorf ~loc
              "[@drop_default] requires either [@option] or [@default]"
      end
    | Some (Some cmp), None -> begin
        (* expression form: [@json.drop_default expr] *)
        match ld_attr_json_option ld, ld_attr_json_default ld with
        | None, Some def -> `Drop_default (cmp, def)
        | Some (), _ ->
            Location.raise_errorf ~loc
              "[@drop_default expr] cannot be used with [@option]"
        | None, None ->
            Location.raise_errorf ~loc
              "[@drop_default expr] requires [@default]"
      end

  (* All declared attributes, passed to [Deriving.Generator.V2.make ~attributes]
     so ppxlib knows the derivers legitimately consume them. The shared ones come
     from [Common]; the rest are [json]-specific. *)
  let attributes =
    attributes
    @ [
        Attribute.T allow_any_cd;
        Attribute.T allow_any_rtag;
        Attribute.T catch_all_cd;
        Attribute.T catch_all_rtag;
        Attribute.T json_drop_default;
        Attribute.T json_drop_default_if_json_equal;
      ]
end

module Jsonschema = struct
  (* Attributes shared with the [json] deriver: [@jsonschema.key],
     [@jsonschema.name], [@jsonschema.allow_extra_fields] /
     [@jsonschema.disallow_extra_fields], [@jsonschema.option],
     [@jsonschema.default] and [@@jsonschema.compact_variants]. *)
  include Common (struct
    let deriver = "jsonschema"
  end)

  type config = {
    polymorphic_variant_tuple : bool;
        (** Preserve the implicit tuple in a polymorphic variant. This
            option breaks compatibility with yojson derivers. *)
    ocaml_doc : bool;
        (** Use [ocaml.doc] attributes (i.e. [(** ... *)] comments) as a
            fallback for [[@jsonschema.description]] when the explicit
            annotation is absent. *)
  }

  let key = record_key

  let ref =
    string_attr "jsonschema.ref" Attribute.Context.label_declaration

  let variant_name = variant_name
  let polymorphic_variant_name = polymorphic_variant_name
  let td_allow_extra_fields = td_allow_extra_fields
  let cd_allow_extra_fields = cd_allow_extra_fields
  let td_disallow_extra_fields = td_disallow_extra_fields
  let cd_disallow_extra_fields = cd_disallow_extra_fields
  let option = record_value_option

  let ld_description =
    string_attr "jsonschema.description"
      Attribute.Context.label_declaration

  let td_description =
    string_attr "jsonschema.description"
      Attribute.Context.type_declaration

  let cd_description =
    string_attr "jsonschema.description"
      Attribute.Context.constructor_declaration

  let ct_description =
    string_attr "jsonschema.description" Attribute.Context.core_type

  let rtag_description =
    string_attr "jsonschema.description" Attribute.Context.rtag

  let td_format =
    string_attr "jsonschema.format" Attribute.Context.type_declaration

  let ld_format =
    string_attr "jsonschema.format" Attribute.Context.label_declaration

  let ct_format =
    string_attr "jsonschema.format" Attribute.Context.core_type

  let td_maximum =
    expr_attr "jsonschema.maximum" Attribute.Context.type_declaration

  let ld_maximum =
    expr_attr "jsonschema.maximum" Attribute.Context.label_declaration

  let ct_maximum =
    expr_attr "jsonschema.maximum" Attribute.Context.core_type

  let td_minimum =
    expr_attr "jsonschema.minimum" Attribute.Context.type_declaration

  let ld_minimum =
    expr_attr "jsonschema.minimum" Attribute.Context.label_declaration

  let ct_minimum =
    expr_attr "jsonschema.minimum" Attribute.Context.core_type

  let ct_attrs = expr_attr "jsonschema.attrs" Attribute.Context.core_type

  let td_attrs =
    expr_attr "jsonschema.attrs" Attribute.Context.type_declaration

  let ld_attrs =
    expr_attr "jsonschema.attrs" Attribute.Context.label_declaration

  let ld_default = ld_default

  let attributes =
    attributes
    @ [
        Attribute.T ref;
        Attribute.T ld_description;
        Attribute.T td_description;
        Attribute.T cd_description;
        Attribute.T ct_description;
        Attribute.T rtag_description;
        Attribute.T td_format;
        Attribute.T ld_format;
        Attribute.T ct_format;
        Attribute.T td_maximum;
        Attribute.T ld_maximum;
        Attribute.T ct_maximum;
        Attribute.T td_minimum;
        Attribute.T ld_minimum;
        Attribute.T ct_minimum;
        Attribute.T ct_attrs;
        Attribute.T td_attrs;
        Attribute.T ld_attrs;
      ]

  (* We intentionally do not use [Attribute.get] for [ocaml.doc]/[doc]. These are
     compiler-reserved attributes, and [ppxlib] rejects registering them via
     [Attribute.declare]. We therefore inspect the raw attribute list directly
     with an [Ast_pattern] that matches both the name and the standard string
     payload shape in one go. *)
  let doc_attr_pattern =
    Ast_pattern.(
      attribute
        ~name:(string "ocaml.doc" ||| string "doc")
        ~payload:(single_expr_payload (estring __')))

  (* A node can carry several [ocaml.doc]/[doc] attributes — e.g. a user writing
     one doc comment before a record field and another after. We collect every
     match and join them with a blank line so each comment reads as its own
     paragraph. The returned location is that of the first matching attribute. *)
  let find_doc_attr attrs =
    let matches =
      List.filter_map
        (fun attr ->
          Ast_pattern.parse_res doc_attr_pattern attr.attr_loc attr Fun.id
          |> Result.to_option
          |> Option.map (fun ({ txt; loc } : string Location.loc) ->
              { txt = String.trim txt; loc }))
        attrs
    in
    match matches with
    | [] -> None
    | [ single ] -> Some single
    | first :: _ as all ->
        Some
          {
            txt = String.concat "\n\n" (List.map (fun x -> x.txt) all);
            loc = first.loc;
          }

  let fallback_description ~ocaml_doc explicit_desc attrs node =
    match Attribute.get explicit_desc node with
    | Some _ as x -> x
    | None -> if ocaml_doc then find_doc_attr attrs else None

  let ld_description ~ocaml_doc (ld : label_declaration) =
    fallback_description ~ocaml_doc ld_description ld.pld_attributes ld

  let td_description ~ocaml_doc (td : type_declaration) =
    fallback_description ~ocaml_doc td_description td.ptype_attributes td

  let cd_description ~ocaml_doc (cd : constructor_declaration) =
    fallback_description ~ocaml_doc cd_description cd.pcd_attributes cd

  let ct_description ~ocaml_doc (ct : core_type) =
    fallback_description ~ocaml_doc ct_description ct.ptyp_attributes ct

  let rtag_description ~ocaml_doc (rf : row_field) =
    fallback_description ~ocaml_doc rtag_description rf.prf_attributes rf

  let td_compact_variants = td_compact_variants

  (* The shared attributes come from [Common]; the rest are [jsonschema]-specific. *)

  let args () =
    Deriving.Args.(
      empty +> flag "polymorphic_variant_tuple" +> flag "ocaml_doc")
end
