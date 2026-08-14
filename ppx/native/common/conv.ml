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

class virtual deriving_fn =
  object (self)
    inherit deriving
    method virtual t : loc:location -> label loc -> core_type -> core_type
    (* The type of the generated term, e.g. [json -> t] for of_json. *)

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

module Record = struct
  (* A record field with its [@json.*] attributes resolved to plain data:
     [key] is the JSON object key ([@json.key], falling back to the OCaml
     field name) and [default] the fallback expression for a missing field
     ([@json.default] / [@json.option]). [ld] carries the raw declaration
     for the drop-default resolution done by [to_fields] below. *)
  type field = {
    name : label loc;
    key : label loc;
    type_ : core_type;
    default : expression option;
    ld : label_declaration;
  }

  type t = { fields : field list; allow_extra_fields : bool }

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

  let of_type_declaration td lds =
    {
      fields = resolve_fields lds;
      allow_extra_fields = Attrs.Json.td_allow_extra_fields td;
    }

  let of_constructor_declaration cd lds =
    {
      fields = resolve_fields lds;
      allow_extra_fields = Attrs.Json.cd_allow_extra_fields cd;
    }

  let of_labeled_tuple ts =
    {
      fields =
        List.map ts ~f:(fun (name, type_) ->
            resolve_field
              (label_declaration ~loc:type_.ptyp_loc ~name ~type_
                 ~mutable_:Immutable));
      allow_extra_fields = true;
    }

  type drop =
    [ `No
    | `Drop_option
    | `Drop_default of expression * expression
    | `Drop_default_if_json_equal of expression ]

  type to_field = { key : label loc; type_ : core_type; drop : drop }

  let to_fields fields =
    List.map fields ~f:(fun (f : field) ->
        {
          key = f.key;
          type_ = f.type_;
          drop = Attrs.Json.ld_drop_default f.ld;
        })
end

module Variant = struct
  type case_attr = { allow_any : bool; catch_all : bool }
  type case_form = Constructor | Tag

  type tuple_case = {
    name : label loc;
    tag : label loc;
    types : core_type list;
    attr : case_attr;
    form : case_form;
  }

  type record_case = {
    name : label loc;
    tag : label loc;
    loc : location;
    record : Record.t;
    attr : case_attr;
  }

  type case = Vcs_tuple of tuple_case | Vcs_record of record_case

  let resolve_attr (ctx : Attrs.Json.case_ctx) : case_attr =
    {
      allow_any = Attrs.Json.vcs_attr_json_allow_any ctx;
      catch_all = Attrs.Json.vcs_attr_json_catch_all ctx;
    }

  let resolve_tag ctx name =
    Option.value ~default:name (Attrs.Json.vcs_attr_json_name ctx)

  (* A [@json.catch_all] case must be able to hold the unknown tag and its
     payload: either a single argument (typically
     [Jsonkit.unknown_variant_case]) or an inline record with exactly
     the fields [tag] and [payload]. Validated once here so the backends
     can assume the shape. *)
  let validate_tuple_case = function
    | { attr = { catch_all = true; _ }; types = [ _ ]; _ } -> ()
    | { name; attr = { catch_all = true; _ }; _ } ->
        Location.raise_errorf ~loc:name.loc
          "[@json.catch_all] requires exactly one argument: a record \
           type with fields `tag : string` and `payload : Jsonkit.t list \
           option` (typically [Jsonkit.unknown_variant_case])"
    | { attr = { catch_all = false; _ }; _ } -> ()

  let validate_record_case = function
    | {
        attr = { catch_all = true; _ };
        record =
          {
            fields =
              [
                { name = { txt = "tag"; _ }; _ };
                { name = { txt = "payload"; _ }; _ };
              ];
            _;
          };
        _;
      } ->
        ()
    | { loc; attr = { catch_all = true; _ }; _ } ->
        Location.raise_errorf ~loc
          "[@json.catch_all] inline record must have exactly two fields \
           named `tag` and `payload` (in that order), with types \
           `string` and `Jsonkit.t list option`"
    | { attr = { catch_all = false; _ }; _ } -> ()

  let validate_case = function
    | Vcs_tuple case -> validate_tuple_case case
    | Vcs_record case -> validate_record_case case

  let case_name = function
    | Vcs_tuple { name; _ } | Vcs_record { name; _ } -> name

  let case_attr = function
    | Vcs_tuple { attr; _ } | Vcs_record { attr; _ } -> attr

  (* Inline records only ever appear on variant constructors. *)
  let case_form = function
    | Vcs_tuple { form; _ } -> form
    | Vcs_record _ -> Constructor

  (* Build / match the OCaml value of a case: [C arg] or [`C arg]. *)
  let case_construct case arg =
    let n = case_name case in
    match case_form case with
    | Constructor -> pexp_construct ~loc:n.loc (map_loc lident n) arg
    | Tag -> pexp_variant ~loc:n.loc n.txt arg

  let case_pattern case arg =
    let n = case_name case in
    match case_form case with
    | Constructor -> ppat_construct ~loc:n.loc (map_loc lident n) arg
    | Tag -> ppat_variant ~loc:n.loc n.txt arg

  let case_pattern_and_args ~loc case =
    match case with
    | Vcs_record { record; _ } ->
        let p, es =
          gen_pat_record ~loc "x"
            (List.map record.fields ~f:(fun (f : Record.field) -> f.name))
        in
        case_pattern case (Some p), es
    | Vcs_tuple { types; _ } ->
        let arity = List.length types in
        let p, es = gen_pat_tuple ~loc "x" arity in
        case_pattern case (if arity = 0 then None else Some p), es

  let case_json_shape ~compact case =
    let payload_holes types =
      List.map types ~f:(fun _ -> ", _") |> String.concat ~sep:""
    in
    match case with
    | Vcs_record { tag; _ } -> Printf.sprintf {|["%s", { _ }]|} tag.txt
    | Vcs_tuple { tag; types = []; _ } when compact ->
        Printf.sprintf {|"%s"|} tag.txt
    | Vcs_tuple { tag; types; _ } ->
        Printf.sprintf {|["%s"%s]|} tag.txt (payload_holes types)

  type polyvariant_case =
    | Pvc_tag of tuple_case
    | Pvc_inherit of longident loc * core_type list

  (* Resolve variant constructors / polymorphic-variant rows into plain
     [case] data (attributes resolved, shapes validated), in declaration
     order. *)
  let resolve_variant_cases ~loc cs =
    List.map cs ~f:(fun (c : constructor_declaration) ->
        let ctx = `Variant_ctx c in
        let attr = resolve_attr ctx in
        let name = c.pcd_name in
        let tag = resolve_tag ctx name in
        let case =
          match c.pcd_args with
          | Pcstr_record fields ->
              Vcs_record
                {
                  name;
                  tag;
                  loc;
                  record = Record.of_constructor_declaration c fields;
                  attr;
                }
          | Pcstr_tuple types ->
              Vcs_tuple { name; tag; types; attr; form = Constructor }
        in
        validate_case case;
        case)

  let resolve_polyvariant_cases cs =
    List.map cs ~f:(fun c ->
        let ctx = `Polyvariant_ctx c in
        let attr = resolve_attr ctx in
        match repr_row_field c with
        | `Rtag (name, types) ->
            let case =
              {
                name;
                tag = resolve_tag ctx name;
                types;
                attr;
                form = Tag;
              }
            in
            validate_tuple_case case;
            Pvc_tag case
        | `Rinherit (n, ts) ->
            if attr.allow_any then
              failwith "[@allow_any] placed on inherit clause";
            Pvc_inherit (n, ts))

  let rec polyvariant_json_shapes ~compact ~loc pvcs =
    List.concat_map pvcs ~f:(function
      | Pvc_tag case -> [ case_json_shape ~compact (Vcs_tuple case) ]
      | Pvc_inherit (n, ts) -> (
          match repr_core_type (ptyp_constr ~loc:n.loc n ts) with
          | `Ptyp_variant rows ->
              polyvariant_json_shapes ~compact ~loc
                (resolve_polyvariant_cases rows)
          | _ -> []))

  let expected_message shapes =
    Printf.sprintf "expected %s" (String.concat ~sep:" or " shapes)

  type variant = {
    compact : bool;
    cases : case list;
    allow_any : (expression -> expression) option;
  }

  type polyvariant = {
    compact : bool;
    pvcs : polyvariant_case list;
    allow_any : (expression -> expression) option;
  }

  let resolve_variant td cs =
    let cases = resolve_variant_cases ~loc:td.ptype_loc cs in
    {
      compact = Attrs.Json.is_compact_variants td;
      cases;
      allow_any =
        List.find_opt cases ~f:(fun case -> (case_attr case).allow_any)
        |> Option.map (fun case e -> case_construct case (Some e));
    }

  let resolve_polyvariant ?td cs =
    let pvcs = resolve_polyvariant_cases cs in
    {
      compact =
        Option.fold ~none:false ~some:Attrs.Json.is_compact_variants td;
      pvcs;
      allow_any =
        List.find_map pvcs ~f:(function
          | Pvc_tag ({ attr = { allow_any = true; _ }; _ } as case) ->
              Some (fun e -> case_construct (Vcs_tuple case) (Some e))
          | _ -> None);
    }

  let without_allow_any cases =
    List.filter cases ~f:(fun case -> not (case_attr case).allow_any)

  let without_allow_any_rows rows pvcs =
    List.combine rows pvcs
    |> List.filter ~f:(fun (_, pvc) ->
        match pvc with
        | Pvc_tag case -> not case.attr.allow_any
        | Pvc_inherit _ -> true)
    |> List.split
end

open Variant

type derive_of_core_type = core_type -> expression -> expression

(* Build a to_json deriver from the backend's JSON emitters: [json_array]
   and [json_string] emit a JSON array/string expression,
   [catch_all_encode] re-emits a [@json.catch_all] payload in its
   original wire shape, and [derive_of_record] emits a JSON object from
   resolved record fields. Everything else — tuple, variant and
   labeled-tuple encoding — is shared here. *)
let deriving_to ~name ~t_to ~json_array ~json_string ~catch_all_encode
    ~(derive_of_record :
       loc:location ->
       derive_of_core_type ->
       Record.to_field list ->
       expression list ->
       expression) () =
  let derive_of_tuple ~loc derive types es =
    json_array ~loc (List.map2 types es ~f:derive)
  in
  let derive_of_record ~loc derive fields es =
    derive_of_record ~loc derive (Record.to_fields fields) es
  in
  let derive_of_labeled_tuple = derive_of_record in
  let derive_of_variant_case ?(is_compact_variants = false) derive case es
      =
    match case with
    | Vcs_tuple { attr = { allow_any = true; _ }; _ } -> (
        match es with
        | [ x ] -> x
        | es ->
            failwith
              (Printf.sprintf "expected a tuple of length 1, got %i"
                 (List.length es)))
    | Vcs_tuple { name; attr = { catch_all = true; _ }; _ } -> (
        let loc = name.loc in
        match es with
        | [ arg_e ] ->
            catch_all_encode ~loc ~tag:[%expr [%e arg_e].tag]
              ~payload:[%expr [%e arg_e].payload]
        | _ -> assert false)
    | Vcs_record { name; attr = { catch_all = true; _ }; _ } -> (
        match es with
        | [ tag_e; payload_e ] ->
            catch_all_encode ~loc:name.loc ~tag:tag_e ~payload:payload_e
        | _ -> assert false)
    | Vcs_record { name; tag; record; _ } ->
        let loc = name.loc in
        json_array ~loc
          [
            json_string ~loc tag;
            derive_of_record ~loc derive record.fields es;
          ]
    | Vcs_tuple { name; tag; types; _ } ->
        let loc = name.loc in
        if is_compact_variants && List.length types = 0 then
          json_string ~loc tag
        else
          json_array ~loc
            (json_string ~loc tag :: List.map2 types es ~f:derive)
  in
  (object (self)
     inherit deriving_fn
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
       let record = Record.of_type_declaration td fs in
       let p, es =
         gen_pat_record ~loc "x"
           (List.map record.fields ~f:(fun (f : Record.field) -> f.name))
       in
       pexp_match ~loc x
         [
           p
           --> derive_of_record ~loc self#derive_of_core_type
                 record.fields es;
         ]

     method! derive_of_labeled_tuple t ts x =
       let loc = t.ptyp_loc in
       let record = Record.of_labeled_tuple ts in
       let p, es = gen_pat_labeled_tuple ~loc "x" ts in
       pexp_match ~loc x
         [
           p
           --> derive_of_labeled_tuple ~loc self#derive_of_core_type
                 record.fields es;
         ]

     method! derive_of_variant td cs x =
       let loc = td.ptype_loc in
       let { compact; cases; _ } = resolve_variant td cs in
       pexp_match ~loc x
         (List.map cases ~f:(fun case ->
              let p, es = case_pattern_and_args ~loc case in
              p
              --> derive_of_variant_case ~is_compact_variants:compact
                    self#derive_of_core_type case es))

     method! derive_of_polyvariant ?td t (cs : row_field list) x =
       let loc = t.ptyp_loc in
       let { compact; pvcs; _ } = resolve_polyvariant ?td cs in
       pexp_match ~loc x
         (List.map pvcs ~f:(fun pvc ->
              match pvc with
              | Pvc_tag case ->
                  let p, es =
                    case_pattern_and_args ~loc (Vcs_tuple case)
                  in
                  p
                  --> derive_of_variant_case ~is_compact_variants:compact
                        self#derive_of_core_type (Vcs_tuple case) es
              | Pvc_inherit (n, ts) ->
                  [%pat? [%p ppat_type ~loc n] as x]
                  --> self#derive_of_core_type
                        (ptyp_constr ~loc:n.loc n ts)
                        [%expr x]))
   end
    :> deriving)
