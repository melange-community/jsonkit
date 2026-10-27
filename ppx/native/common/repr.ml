open Printf
open Ppxlib
open Ast_builder.Default
open StdLabels
open Ast_helpers

let repr_row_field field =
  match field.prf_desc with
  | Rtag (id, _, []) -> `Rtag (id, [])
  | Rtag (id, _, [ { ptyp_desc = Ptyp_tuple ts; _ } ]) -> `Rtag (id, ts)
  | Rtag (id, _, [ t ]) -> `Rtag (id, [ t ])
  | Rtag (_, _, _ :: _) ->
      not_supported ~loc:field.prf_loc
        "polyvariant constructor with more than one argument"
  | Rinherit { ptyp_desc = Ptyp_constr (id, ts); _ } -> `Rinherit (id, ts)
  | Rinherit _ ->
      not_supported ~loc:field.prf_loc "this polyvariant inherit"

let invalid_labeled_tuple ~loc fmt =
  ksprintf
    (Location.raise_errorf ~loc
       "ppxlib.migration.ptyp_labeled_tuple_5_4: %s")
    fmt

let rec repr_core_type ty =
  let loc = ty.ptyp_loc in
  match ty.ptyp_desc with
  | Ptyp_tuple ts -> `Ptyp_tuple ts
  | Ptyp_constr (id, ts) -> `Ptyp_constr (id, ts)
  | Ptyp_var txt -> `Ptyp_var { txt; loc = ty.ptyp_loc }
  | Ptyp_variant (fs, Closed, None) -> `Ptyp_variant fs
  | Ptyp_open (id, ct) -> `Ptyp_open (id, repr_core_type ct)
  | Ptyp_extension
      ( { txt = "ppxlib.migration.ptyp_labeled_tuple_5_4"; _ },
        PTyp { ptyp_desc = Ptyp_tuple xs; _ } ) ->
      let xs =
        List.mapi xs ~f:(fun i ct ->
            match ct with
            | [%type: _ * [%t? v]] ->
                { txt = string_of_int i; loc = v.ptyp_loc }, v
            | [%type: [%t? k] * [%t? v]] -> begin
                match k with
                | { ptyp_desc = Ptyp_var txt; ptyp_loc = loc; _ } ->
                    { txt; loc }, v
                | _ ->
                    invalid_labeled_tuple ~loc
                      "invalid key in labeled tuple"
              end
            | _ -> invalid_labeled_tuple ~loc "invalid representation")
      in
      `Ptyp_labeled_tuple xs
  | Ptyp_extension
      ({ txt = "ppxlib.migration.ptyp_labeled_tuple_5_4"; _ }, _) ->
      invalid_labeled_tuple ~loc "invalid representation"
  | Ptyp_extension (name, _) ->
      not_supportedf ~loc "extension nodes (%s)" name.txt
  | Ptyp_variant _ ->
      Location.raise_errorf ~loc
        "non closed polyvariants ([> ...] and [< ...]) are not \
         supported; for forward compatibility use a closed polyvariant \
         with a [@json.catch_all] or [@json.allow_any] row"
  | Ptyp_arrow _ -> not_supported ~loc "function types"
  | Ptyp_any -> not_supported ~loc "type placeholders"
  | Ptyp_object _ -> not_supported ~loc "object types"
  | Ptyp_class _ -> not_supported ~loc "class types"
  | Ptyp_poly _ -> not_supported ~loc "polymorphic type expressions"
  | Ptyp_package _ -> not_supported ~loc "packaged module types"
  | Ptyp_alias _ -> not_supported ~loc "type aliases"

let repr_type_declaration td =
  let loc = td.ptype_loc in
  match td.ptype_kind, td.ptype_manifest with
  | Ptype_abstract, None -> not_supported ~loc "abstract types"
  | Ptype_abstract, Some t -> `Ptype_core_type t
  | Ptype_variant ctors, _ -> `Ptype_variant ctors
  | Ptype_record fs, _ -> `Ptype_record fs
  | Ptype_open, _ -> not_supported ~loc "open types"

let gen_type_ascription (td : type_declaration) =
  let loc = td.ptype_loc in
  ptyp_constr ~loc
    { loc; txt = lident td.ptype_name.txt }
    (List.map td.ptype_params ~f:(fun (p, _) ->
         match p.ptyp_desc with
         | Ptyp_var name -> ptyp_var ~loc name
         | Ptyp_any -> ptyp_any ~loc
         | _ ->
             Location.raise_errorf ~loc "this cannot be a type parameter"))

let derive_sig_type_decl ~derive_t ~derive_label ~ctxt (_rec_flag, tds) =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  List.map tds ~f:(fun td ->
      let name = td.ptype_name in
      let type_ = derive_t ~loc name (gen_type_ascription td) in
      let type_ =
        List.fold_left (List.rev td.ptype_params) ~init:type_
          ~f:(fun acc (t, _) ->
            let loc = t.ptyp_loc in
            let name =
              match t.ptyp_desc with
              | Ptyp_var txt -> { txt; loc }
              | _ ->
                  Location.raise_errorf ~loc
                    "type variable is not a variable"
            in
            let t = derive_t ~loc name t in
            ptyp_arrow ~loc Nolabel t acc)
      in
      psig_value ~loc
        (value_description ~loc ~prim:[] ~name:(derive_label name) ~type_))
