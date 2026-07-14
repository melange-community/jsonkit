open Ppxlib
open Ast_builder.Default
open StdLabels
open Ast_helpers
open Repr

class virtual deriving =
  object
    method virtual name : label

    method virtual extension
        : loc:location -> path:label -> core_type -> expression

    method virtual str_type_decl
        : ctxt:Expansion_context.Deriver.t ->
          rec_flag * type_declaration list ->
          structure

    method virtual sig_type_decl
        : ctxt:Expansion_context.Deriver.t ->
          rec_flag * type_declaration list ->
          signature
  end

let register ?deps deriving =
  let args = Deriving.Args.empty in
  let attributes = Attrs.Json.attributes in
  let str_type_decl = deriving#str_type_decl in
  let sig_type_decl = deriving#sig_type_decl in
  Deriving.add deriving#name ~extension:deriving#extension
    ~str_type_decl:
      (Deriving.Generator.V2.make ?deps ~attributes args str_type_decl)
    ~sig_type_decl:
      (Deriving.Generator.V2.make ?deps ~attributes args sig_type_decl)

let register_combined ?deps name derivings =
  let args = Deriving.Args.empty in
  let attributes = Attrs.Json.attributes in
  let str_type_decl ~ctxt bindings =
    List.fold_left derivings ~init:[] ~f:(fun str d ->
        d#str_type_decl ~ctxt bindings @ str)
  in
  let sig_type_decl ~ctxt bindings =
    List.fold_left derivings ~init:[] ~f:(fun str d ->
        d#sig_type_decl ~ctxt bindings @ str)
  in
  Deriving.add name
    ~str_type_decl:
      (Deriving.Generator.V2.make ?deps ~attributes args str_type_decl)
    ~sig_type_decl:
      (Deriving.Generator.V2.make ?deps ~attributes args sig_type_decl)

class virtual deriving1 =
  object (self)
    inherit deriving
    method virtual t : loc:location -> label loc -> core_type -> core_type

    method derive_of_tuple :
        core_type -> core_type list -> expression -> expression =
      fun t _ _ ->
        let loc = t.ptyp_loc in
        not_supported "tuple types" ~loc

    method derive_of_labeled_tuple :
        core_type ->
        (label loc * core_type) list ->
        expression ->
        expression =
      fun t _ _ ->
        let loc = t.ptyp_loc in
        not_supported "labeled tuple types" ~loc

    method derive_of_record :
        type_declaration ->
        label_declaration list ->
        expression ->
        expression =
      fun td _ _ ->
        let loc = td.ptype_loc in
        not_supported "record types" ~loc

    method derive_of_variant :
        type_declaration ->
        constructor_declaration list ->
        expression ->
        expression =
      fun td _ _ ->
        let loc = td.ptype_loc in
        not_supported "variant types" ~loc

    method derive_of_polyvariant :
        ?td:type_declaration ->
        core_type ->
        row_field list ->
        expression ->
        expression =
      fun ?td:_ t _ _ ->
        let loc = t.ptyp_loc in
        not_supported "polyvariant types" ~loc

    method private derive_type_ref_name :
        label -> longident loc -> expression =
      fun name n -> ederiver name n

    method private derive_type_ref' ~loc name n ts =
      let f = self#derive_type_ref_name name n in
      let args =
        List.fold_left (List.rev ts) ~init:[] ~f:(fun args a ->
            let a = as_fun ~loc (self#derive_of_core_type' a) in
            (Nolabel, a) :: args)
      in
      As_val (pexp_apply ~loc f args)

    method derive_type_ref ~loc name n ts x =
      as_val ~loc (self#derive_type_ref' ~loc name n ts) x

    method private derive_of_core_type' t =
      let loc = t.ptyp_loc in
      self#derive_of_core_type_repr ~loc t (repr_core_type t)

    method private derive_of_core_type_repr ?opn ~loc t repr =
      match repr with
      | `Ptyp_tuple ts -> As_fun (self#derive_of_tuple t ts)
      | `Ptyp_labeled_tuple ts ->
          As_fun (self#derive_of_labeled_tuple t ts)
      | `Ptyp_var label ->
          As_val
            (ederiver self#name
               (map_loc (lident_with_optional_open ?opn) label))
      | `Ptyp_open (_, `Ptyp_open _) -> assert false
      | `Ptyp_open (lid, ct) ->
          self#derive_of_core_type_repr ~opn:lid ~loc t ct
      | `Ptyp_constr (id, ts) ->
          let id =
            match opn with
            | Some { txt = lid; loc } ->
                {
                  txt =
                    Lid.flatten lid @ Lid.flatten id.txt
                    |> Lid.unflatten
                    |> Option.get;
                  loc;
                }
            | None -> id
          in
          self#derive_type_ref' self#name ~loc id ts
      | `Ptyp_variant fs -> As_fun (self#derive_of_polyvariant t fs)

    method derive_of_core_type t x =
      let loc = x.pexp_loc in
      as_val ~loc (self#derive_of_core_type' t) x

    method private derive_type_decl_label name =
      map_loc (derive_of_label self#name) name

    method derive_of_type_declaration td =
      let loc = td.ptype_loc in
      let name = td.ptype_name in
      let rev_params =
        List.rev_map td.ptype_params ~f:(fun (t, _) ->
            match t.ptyp_desc with
            | Ptyp_var txt -> { txt; loc = t.ptyp_loc }
            | Ptyp_any ->
                { txt = gen_symbol ~prefix:"_" (); loc = t.ptyp_loc }
            | _ ->
                Location.raise_errorf ~loc
                  "type variable is not a variable")
      in
      let x = [%expr x] in
      let expr =
        match repr_type_declaration td with
        | `Ptype_core_type
            ({ ptyp_desc = Ptyp_variant (fs, _, _); _ } as t) ->
            self#derive_of_polyvariant ~td t fs x
        | `Ptype_core_type t -> self#derive_of_core_type t x
        | `Ptype_variant ctors -> self#derive_of_variant td ctors x
        | `Ptype_record fs -> self#derive_of_record td fs x
      in
      let expr =
        [%expr
          (fun x -> [%e expr]
            : [%t self#t ~loc name (gen_type_ascription td)])]
      in
      let expr =
        List.fold_left rev_params ~init:expr ~f:(fun body param ->
            pexp_fun ~loc Nolabel None
              (ppat_var ~loc (map_loc (derive_of_label self#name) param))
              body)
      in
      [
        value_binding ~loc
          ~pat:(ppat_var ~loc (self#derive_type_decl_label name))
          ~expr;
      ]

    method extension :
        loc:location -> path:label -> core_type -> expression =
      fun ~loc:_ ~path:_ ty ->
        let loc = ty.ptyp_loc in
        as_fun ~loc (self#derive_of_core_type' ty)

    method str_type_decl :
        ctxt:Expansion_context.Deriver.t ->
        rec_flag * type_declaration list ->
        structure =
      fun ~ctxt (rec_flag, tds) ->
        let loc = Expansion_context.Deriver.derived_item_loc ctxt in
        let bindings =
          List.concat_map tds ~f:self#derive_of_type_declaration
        in
        [%str
          [@@@ocaml.warning "-39-11-27"]

          [%%i pstr_value ~loc rec_flag bindings]]

    method sig_type_decl :
        ctxt:Expansion_context.Deriver.t ->
        rec_flag * type_declaration list ->
        signature =
      derive_sig_type_decl ~derive_t:self#t
        ~derive_label:self#derive_type_decl_label
  end

let rec get_variant_names ?(compact = false) ~loc c =
  match repr_row_field c with
  | `Rtag (name, ts) ->
      let name =
        Option.value ~default:name
          (Attribute.get Attrs.Json.attr_json_name_rtag c)
      in
      [
        (if compact && ts = [] then Printf.sprintf {|"%s"|} name.txt
         else
           Printf.sprintf {|["%s"%s]|} name.txt
             (ts |> List.map ~f:(fun _ -> ", _") |> String.concat ~sep:""));
      ]
  | `Rinherit (n, ts) -> (
      match repr_core_type (ptyp_constr ~loc:n.loc n ts) with
      | `Ptyp_variant fields ->
          List.concat_map fields ~f:(get_variant_names ~compact ~loc)
      | _ -> [])

module Record = struct
  (* A record field with its [@json.*] attributes resolved to plain data:
     [key] is the JSON object key ([@json.key], falling back to the OCaml
     field name) and [default] the fallback expression for a missing field
     ([@json.default] / [@json.option]). [ld] carries the raw declaration
     for the drop-default resolution, which only the to_json direction
     performs (resolving it eagerly would reject attribute combinations
     that of_json-only derivations accept today). *)
  type field = {
    name : label loc;
    key : label loc;
    type_ : core_type;
    default : expression option;
    ld : label_declaration;
  }

  let resolve_field (ld : label_declaration) =
    {
      name = ld.pld_name;
      key =
        Option.value ~default:ld.pld_name (Attrs.Json.ld_attr_json_key ld);
      type_ = ld.pld_type;
      default = Attrs.Json.ld_attr_default ld;
      ld;
    }

  let resolve_fields lds = List.map lds ~f:resolve_field

  (* Labeled-tuple components convert like record fields without attributes. *)
  let fields_of_labeled_tuple ts =
    List.map ts ~f:(fun (name, type_) ->
        resolve_field
          (label_declaration ~loc:type_.ptyp_loc ~name ~type_
             ~mutable_:Immutable))
end

module Variant = struct
  type case_attr = {
    allow_any : bool;
    catch_all : bool;
    json_name : label loc option;
  }

  type case_ctx =
    [ `Variant_ctx of constructor_declaration
    | `Polyvariant_ctx of row_field ]

  type case =
    | Vcs_tuple of {
        name : label loc;
        loc : location;
        types : core_type list;
        attr : case_attr;
      }
    | Vcs_record of {
        name : label loc;
        loc : location;
        fields : Record.field list;
        attr : case_attr;
        allow_extra_fields : bool;
      }

  let resolve_attr ctx : case_attr =
    {
      allow_any = Attrs.Json.vcs_attr_json_allow_any ctx;
      catch_all = Attrs.Json.vcs_attr_json_catch_all ctx;
      json_name = Attrs.Json.vcs_attr_json_name ctx;
    }

  (* A [@json.catch_all] case must be able to hold the unknown tag and its
     payload: either a single argument (typically
     [Jsonkit.unknown_variant_case]) or an inline record with exactly
     the fields [tag] and [payload]. Validated once here so the backends
     can assume the shape. *)
  let validate_case = function
    | Vcs_tuple { attr = { catch_all = true; _ }; types = [ _ ]; _ } -> ()
    | Vcs_tuple { name; attr = { catch_all = true; _ }; _ } ->
        Location.raise_errorf ~loc:name.loc
          "[@json.catch_all] requires exactly one argument: a record \
           type with fields `tag : string` and `payload : Jsonkit.t list \
           option` (typically [Jsonkit.unknown_variant_case])"
    | Vcs_record
        {
          attr = { catch_all = true; _ };
          fields =
            [
              { name = { txt = "tag"; _ }; _ };
              { name = { txt = "payload"; _ }; _ };
            ];
          _;
        } ->
        ()
    | Vcs_record { loc; attr = { catch_all = true; _ }; _ } ->
        Location.raise_errorf ~loc
          "[@json.catch_all] inline record must have exactly two fields \
           named `tag` and `payload` (in that order), with types \
           `string` and `Jsonkit.t list option`"
    | Vcs_tuple _ | Vcs_record _ -> ()

  let case_name = function
    | Vcs_tuple { name; _ } | Vcs_record { name; _ } -> name

  let case_attr = function
    | Vcs_tuple { attr; _ } | Vcs_record { attr; _ } -> attr

  (* Wire shape of a case, as shown in "expected ..." decode errors. *)
  let case_wire_shape ~compact case =
    match case with
    | Vcs_record { name; attr; _ } ->
        let name = Option.value ~default:name attr.json_name in
        Printf.sprintf {|["%s", { _ }]|} name.txt
    | Vcs_tuple { name; types; attr; _ } ->
        let name = Option.value ~default:name attr.json_name in
        if compact && types = [] then Printf.sprintf {|"%s"|} name.txt
        else
          Printf.sprintf {|["%s"%s]|} name.txt
            (types
            |> List.map ~f:(fun _ -> ", _")
            |> String.concat ~sep:"")

  type polyvariant_case =
    | Pvc_case of case
    | Pvc_inherit of longident loc * core_type list

  (* Resolve variant constructors / polymorphic-variant rows into plain
     [case] data (attributes resolved, shapes validated), in declaration
     order. *)
  let resolve_variant_cases ~loc cs =
    List.map cs ~f:(fun (c : constructor_declaration) ->
        let attr = resolve_attr (`Variant_ctx c) in
        let case =
          match c.pcd_args with
          | Pcstr_record fields ->
              Vcs_record
                {
                  name = c.pcd_name;
                  loc;
                  fields = Record.resolve_fields fields;
                  attr;
                  allow_extra_fields = Attrs.Json.cd_allow_extra_fields c;
                }
          | Pcstr_tuple types ->
              Vcs_tuple { name = c.pcd_name; loc; types; attr }
        in
        validate_case case;
        case)

  let resolve_polyvariant_cases ~loc cs =
    List.map cs ~f:(fun c ->
        let attr = resolve_attr (`Polyvariant_ctx c) in
        match repr_row_field c with
        | `Rtag (n, ts) ->
            let case = Vcs_tuple { name = n; loc; types = ts; attr } in
            validate_case case;
            Pvc_case case
        | `Rinherit (n, ts) ->
            if attr.allow_any then
              failwith "[@allow_any] placed on inherit clause";
            Pvc_inherit (n, ts))
end

open Variant

type derive_of_core_type = core_type -> expression -> expression

let deriving_to ~name ~t_to ~derive_of_tuple ~derive_of_labeled_tuple
    ~derive_of_record
    ~(derive_of_variant_case :
       ?is_compact_variants:bool ->
       derive_of_core_type ->
       Variant.case ->
       expression list ->
       expression) () =
  (object (self)
     inherit deriving1
     method name = name
     method t ~loc _name t = [%type: [%t t] -> [%t t_to ~loc]]

     method! derive_of_tuple t ts x =
       let loc = t.ptyp_loc in
       let n = List.length ts in
       let p, es = gen_pat_tuple ~loc "x" n in
       pexp_match ~loc x
         [ p --> derive_of_tuple ~loc self#derive_of_core_type ts es ]

     method! derive_of_record td fs x =
       let loc = td.ptype_loc in
       let p, es = gen_pat_record ~loc "x" fs in
       pexp_match ~loc x
         [
           p
           --> derive_of_record ~loc self#derive_of_core_type
                 (Record.resolve_fields fs)
                 es;
         ]

     method! derive_of_labeled_tuple t ts x =
       let loc = t.ptyp_loc in
       let fs = Record.fields_of_labeled_tuple ts in
       let p, es = gen_pat_labeled_tuple ~loc "x" ts in
       pexp_match ~loc x
         [
           p
           --> derive_of_labeled_tuple ~loc self#derive_of_core_type fs es;
         ]

     method! derive_of_variant td cs x =
       let loc = td.ptype_loc in
       let compact = Attrs.Json.is_compact_variants td in
       let ctor_pat (n : label loc) pat =
         ppat_construct ~loc:n.loc (map_loc lident n) pat
       in
       pexp_match ~loc x
         (List.map (resolve_variant_cases ~loc cs) ~f:(fun case ->
              match case with
              | Vcs_record { name = n; fields; _ } ->
                  let p, es =
                    gen_pat_record ~loc "x"
                      (List.map fields ~f:(fun (f : Record.field) -> f.ld))
                  in
                  ctor_pat n (Some p)
                  --> derive_of_variant_case ~is_compact_variants:compact
                        self#derive_of_core_type case es
              | Vcs_tuple { name = n; types; _ } ->
                  let arity = List.length types in
                  let p, es = gen_pat_tuple ~loc "x" arity in
                  ctor_pat n (if arity = 0 then None else Some p)
                  --> derive_of_variant_case ~is_compact_variants:compact
                        self#derive_of_core_type case es))

     method! derive_of_polyvariant ?td t (cs : row_field list) x =
       let loc = t.ptyp_loc in
       let compact =
         Option.fold ~none:false ~some:Attrs.Json.is_compact_variants td
       in
       pexp_match ~loc x
         (List.map (resolve_polyvariant_cases ~loc cs) ~f:(fun pvc ->
              match pvc with
              | Pvc_case (Vcs_tuple { name = n; types = []; _ } as case)
                ->
                  ppat_variant ~loc n.txt None
                  --> derive_of_variant_case ~is_compact_variants:compact
                        self#derive_of_core_type case []
              | Pvc_case (Vcs_tuple { name = n; types = ts; _ } as case)
                ->
                  let ps, es = gen_pat_tuple ~loc "x" (List.length ts) in
                  ppat_variant ~loc n.txt (Some ps)
                  --> derive_of_variant_case ~is_compact_variants:compact
                        self#derive_of_core_type case es
              | Pvc_case (Vcs_record _) ->
                  (* polymorphic-variant tags carry no inline records *)
                  assert false
              | Pvc_inherit (n, ts) ->
                  [%pat? [%p ppat_type ~loc n] as x]
                  --> self#derive_of_core_type
                        (ptyp_constr ~loc:n.loc n ts)
                        [%expr x]))
   end
    :> deriving)
