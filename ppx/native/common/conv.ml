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

let get_constructor_names ?(compact = false) cs =
  List.map cs ~f:(fun c ->
      let name =
        Option.value ~default:c.pcd_name
          (Attribute.get Attrs.Json.attr_json_name_cd c)
      in
      match c.pcd_args with
      | Pcstr_record _fs -> Printf.sprintf {|["%s", { _ }]|} name.txt
      | Pcstr_tuple [] when compact -> Printf.sprintf {|"%s"|} name.txt
      | Pcstr_tuple li ->
          Printf.sprintf {|["%s"%s]|} name.txt
            (li |> List.map ~f:(fun _ -> ", _") |> String.concat ~sep:""))

type 'ctx tuple = {
  tpl_loc : location;
  tpl_types : core_type list;
  tpl_ctx : 'ctx;
}

type 'ctx record = {
  rcd_loc : location;
  rcd_fields : label_declaration list;
  rcd_ctx : 'ctx;
}

type variant_case_ctx =
  [ `Variant_ctx of constructor_declaration
  | `Polyvariant_ctx of row_field ]

type variant_case =
  | Vcs_tuple of label loc * variant_case_ctx tuple
  | Vcs_record of label loc * variant_case_ctx record

type variant = { vrt_loc : location; vrt_cases : variant_case list }
type derive_of_core_type = core_type -> expression -> expression

let repr_polyvariant_cases cs =
  List.rev cs |> List.map ~f:(fun c -> c, repr_row_field c)

let repr_variant_cases cs = List.rev cs

let deriving_of ~name ~of_t ~is_allow_any_constr ~derive_of_tuple
    ~derive_of_labeled_tuple ~derive_of_record
    ~(derive_of_variant :
       ?is_compact_variants:bool ->
       derive_of_core_type ->
       variant ->
       allow_any_constr:(expression -> expression) option ->
       (array:expression ->
       len:expression ->
       tag:expression ->
       expression) ->
       expression ->
       expression)
    ~(derive_of_variant_case :
       ?is_compact_variants:bool ->
       tag:expression ->
       array:expression ->
       len:expression ->
       derive_of_core_type ->
       ((array:expression -> len:expression -> expression) option ->
       expression) ->
       variant_case ->
       allow_any_constr:(expression -> expression) option ->
       expression ->
       expression) () =
  (object (self)
     inherit deriving1
     method name = name
     method t ~loc _name t = [%type: [%t of_t ~loc] -> [%t t]]

     method! derive_of_tuple t ts x =
       let t = { tpl_loc = t.ptyp_loc; tpl_types = ts; tpl_ctx = t } in
       derive_of_tuple self#derive_of_core_type t x

     method! derive_of_labeled_tuple t ts x =
       let fs =
         List.map ts ~f:(fun (name, type_) ->
             let loc = type_.ptyp_loc in
             label_declaration ~loc ~name ~type_ ~mutable_:Immutable)
       in
       let t = { rcd_loc = t.ptyp_loc; rcd_fields = fs; rcd_ctx = () } in
       derive_of_labeled_tuple self#derive_of_core_type t x

     method! derive_of_record td fs x =
       let t =
         { rcd_loc = td.ptype_loc; rcd_fields = fs; rcd_ctx = td }
       in
       derive_of_record self#derive_of_core_type t x

     method! derive_of_variant td cs x =
       let loc = td.ptype_loc in
       let cs = repr_variant_cases cs in
       let allow_any_constr =
         cs
         |> List.find_opt ~f:(fun cs ->
             is_allow_any_constr (`Variant_ctx cs))
         |> Option.map (fun cs e -> econstruct cs (Some e))
       in
       let cs =
         List.filter
           ~f:(fun cs -> not (is_allow_any_constr (`Variant_ctx cs)))
           cs
       in
       let compact = Attrs.Json.is_compact_variants td in
       let body, cases =
         List.fold_left cs
           ~init:
             (match allow_any_constr with
             | Some allow_any_constr ->
                 (fun ~array:_ ~len:_ ~tag:_ -> allow_any_constr x), []
             | None ->
                 let error_message =
                   Printf.sprintf "expected %s"
                     (get_constructor_names ~compact cs
                     |> String.concat ~sep:" or ")
                 in
                 ( (fun ~array:_ ~len:_ ~tag:_ ->
                     [%expr
                       Jsonkit.of_json_error ~json:[%e x]
                         [%e estring ~loc error_message]]),
                   [] ))
           ~f:(fun (next, cases) c ->
             let make ~array ~len (n : label loc) build =
               let arg = Option.map (fun b -> b ~array ~len) build in
               pexp_construct (map_loc lident n) ~loc:n.loc arg
             in
             let ctx = `Variant_ctx c in
             let n = c.pcd_name in
             match c.pcd_args with
             | Pcstr_record fs ->
                 let t =
                   let t =
                     { rcd_loc = loc; rcd_fields = fs; rcd_ctx = ctx }
                   in
                   Vcs_record (n, t)
                 in
                 let next ~array ~len ~tag =
                   derive_of_variant_case ~is_compact_variants:compact
                     ~tag ~array ~len self#derive_of_core_type
                     (make ~array ~len n) t ~allow_any_constr
                     (next ~array ~len ~tag)
                 in
                 next, t :: cases
             | Pcstr_tuple ts ->
                 let case =
                   let t =
                     { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx }
                   in
                   Vcs_tuple (n, t)
                 in
                 let next ~array ~len ~tag =
                   derive_of_variant_case ~is_compact_variants:compact
                     ~tag ~array ~len self#derive_of_core_type
                     (make ~array ~len n) case ~allow_any_constr
                     (next ~array ~len ~tag)
                 in
                 next, case :: cases)
       in
       let t = { vrt_loc = loc; vrt_cases = cases } in
       derive_of_variant ~is_compact_variants:compact
         self#derive_of_core_type t ~allow_any_constr body x

     method! derive_of_polyvariant ?td t (cs : row_field list) x =
       let loc = t.ptyp_loc in
       let compact =
         Option.fold ~none:false ~some:Attrs.Json.is_compact_variants td
       in
       let allow_any_constr =
         cs
         |> List.find_opt ~f:(fun cs ->
             is_allow_any_constr (`Polyvariant_ctx cs))
         |> Option.map (fun cs ->
             match cs.prf_desc with
             | Rinherit _ ->
                 failwith "[@allow_any] placed on inherit clause"
             | Rtag (n, _, _) ->
                 fun e -> pexp_variant ~loc:n.loc n.txt (Some e))
       in
       let cs =
         List.filter
           ~f:(fun cs -> not (is_allow_any_constr (`Polyvariant_ctx cs)))
           cs
       in
       let cases = repr_polyvariant_cases cs in
       let body, cases =
         List.fold_left cases
           ~init:
             (match allow_any_constr with
             | Some allow_any_constr ->
                 (fun ~array:_ ~len:_ ~tag:_ -> allow_any_constr x), []
             | None ->
                 let error_message =
                   Printf.sprintf "expected %s"
                     (cs
                     |> List.concat_map
                          ~f:(get_variant_names ~compact ~loc)
                     |> String.concat ~sep:" or ")
                 in
                 ( (fun ~array:_ ~len:_ ~tag:_ ->
                     [%expr
                       Jsonkit.of_json_unexpected_variant ~json:x
                         [%e estring ~loc error_message]]),
                   [] ))
           ~f:(fun (next, cases) (c, r) ->
             let ctx = `Polyvariant_ctx c in
             match r with
             | `Rtag (n, ts) ->
                 let make ~array ~len build =
                   let arg = Option.map (fun b -> b ~array ~len) build in
                   pexp_variant ~loc:n.loc n.txt arg
                 in
                 let case =
                   let t =
                     { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx }
                   in
                   Vcs_tuple (n, t)
                 in
                 let next ~array ~len ~tag =
                   derive_of_variant_case ~is_compact_variants:compact
                     ~tag ~array ~len self#derive_of_core_type
                     (make ~array ~len) case ~allow_any_constr
                     (next ~array ~len ~tag)
                 in
                 next, case :: cases
             | `Rinherit (n, ts) ->
                 let maybe_e =
                   self#derive_type_ref ~loc self#name n ts x
                 in
                 let t = ptyp_variant ~loc cs Closed None in
                 let next ~array ~len ~tag =
                   [%expr
                     match [%e maybe_e] with
                     | e -> (e :> [%t t])
                     | exception
                         Jsonkit.Of_json_error
                           (Jsonkit.Unexpected_variant _) ->
                         [%e next ~array ~len ~tag]]
                 in
                 next, cases)
       in
       let t = { vrt_loc = loc; vrt_cases = cases } in
       derive_of_variant ~is_compact_variants:compact
         self#derive_of_core_type t ~allow_any_constr body x
   end
    :> deriving)

let deriving_of_match ~name ~of_t ~cmp_sort_vcs ~derive_of_tuple
    ~derive_of_labeled_tuple ~derive_of_record
    ~(derive_of_variant_case :
       ?is_compact_variants:bool -> _ -> _ -> _ -> _) () =
  (object (self)
     inherit deriving1
     method name = name
     method t ~loc _name t = [%type: [%t of_t ~loc] -> [%t t]]

     method! derive_of_tuple t ts x =
       let t = { tpl_loc = t.ptyp_loc; tpl_types = ts; tpl_ctx = t } in
       derive_of_tuple self#derive_of_core_type t x

     method! derive_of_labeled_tuple t ts x =
       let fs =
         List.map ts ~f:(fun (name, type_) ->
             let loc = type_.ptyp_loc in
             label_declaration ~loc ~name ~type_ ~mutable_:Immutable)
       in
       let t = { rcd_loc = t.ptyp_loc; rcd_fields = fs; rcd_ctx = () } in
       derive_of_labeled_tuple self#derive_of_core_type t x

     method! derive_of_record td fs x =
       let t =
         { rcd_loc = td.ptype_loc; rcd_fields = fs; rcd_ctx = td }
       in
       derive_of_record self#derive_of_core_type t x

     method! derive_of_variant td cs x =
       let loc = td.ptype_loc in
       let compact = Attrs.Json.is_compact_variants td in
       let error_message =
         Printf.sprintf "expected %s"
           (get_constructor_names ~compact cs |> String.concat ~sep:" or ")
       in
       let cs = repr_variant_cases cs in
       let cs =
         List.stable_sort
           ~cmp:(fun cs1 cs2 ->
             let vcs1 = `Variant_ctx cs1 and vcs2 = `Variant_ctx cs2 in
             cmp_sort_vcs vcs1 vcs2)
           cs
       in
       let cases =
         List.fold_left cs
           ~init:
             [
               [%pat? _]
               --> [%expr
                     Jsonkit.of_json_error ~json:x
                       [%e estring ~loc error_message]];
             ]
           ~f:(fun next (c : constructor_declaration) ->
             let ctx = `Variant_ctx c in
             let make (n : label loc) arg =
               pexp_construct (map_loc lident n) ~loc:n.loc arg
             in
             let n = c.pcd_name in
             match c.pcd_args with
             | Pcstr_record fs ->
                 let t =
                   let r =
                     { rcd_loc = loc; rcd_fields = fs; rcd_ctx = ctx }
                   in
                   Vcs_record (n, r)
                 in
                 derive_of_variant_case self#derive_of_core_type
                   ~is_compact_variants:compact (make n) t
                 :: next
             | Pcstr_tuple ts ->
                 let t =
                   let t =
                     { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx }
                   in
                   Vcs_tuple (n, t)
                 in
                 derive_of_variant_case self#derive_of_core_type
                   ~is_compact_variants:compact (make n) t
                 :: next)
       in
       pexp_match ~loc x cases

     method! derive_of_polyvariant ?td t (cs : row_field list) x =
       let loc = t.ptyp_loc in
       let compact =
         Option.fold ~none:false ~some:Attrs.Json.is_compact_variants td
       in
       let cases = repr_polyvariant_cases cs in
       let cases =
         List.stable_sort
           ~cmp:(fun (cs1, _) (cs2, _) ->
             let vcs1 = `Polyvariant_ctx cs1
             and vcs2 = `Polyvariant_ctx cs2 in
             cmp_sort_vcs vcs1 vcs2)
           cases
       in
       let ctors, inherits =
         List.partition_map cases ~f:(fun (c, r) ->
             let ctx = `Polyvariant_ctx c in
             match r with
             | `Rtag (n, ts) ->
                 let t =
                   { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx }
                 in
                 Left (n, Vcs_tuple (n, t))
             | `Rinherit (n, ts) -> Right (n, ts))
       in
       let catch_all =
         [%pat? x]
         --> List.fold_left (List.rev inherits)
               ~init:
                 (let error_message =
                    Printf.sprintf "expected %s"
                      (cs
                      |> List.concat_map
                           ~f:(get_variant_names ~compact ~loc)
                      |> String.concat ~sep:" or ")
                  in
                  [%expr
                    Jsonkit.of_json_unexpected_variant ~json:x
                      [%e estring ~loc error_message]])
               ~f:(fun next (n, ts) ->
                 let maybe = self#derive_type_ref ~loc self#name n ts x in
                 let t = ptyp_variant ~loc cs Closed None in
                 [%expr
                   match [%e maybe] with
                   | x -> (x :> [%t t])
                   | exception
                       Jsonkit.Of_json_error
                         (Jsonkit.Unexpected_variant _) ->
                       [%e next]])
       in
       let cases =
         List.fold_left ctors ~init:[ catch_all ]
           ~f:(fun next ((n : label loc), t) ->
             let make arg = pexp_variant ~loc:n.loc n.txt arg in
             derive_of_variant_case ~is_compact_variants:compact
               self#derive_of_core_type make t
             :: next)
       in
       pexp_match ~loc x cases
   end
    :> deriving)

let deriving_to ~name ~t_to ~derive_of_tuple ~derive_of_labeled_tuple
    ~derive_of_record
    ~(derive_of_variant_case :
       ?is_compact_variants:bool ->
       derive_of_core_type ->
       variant_case ->
       expression list ->
       expression) () =
  (object (self)
     inherit deriving1
     method name = name
     method t ~loc _name t = [%type: [%t t] -> [%t t_to ~loc]]

     method! derive_of_tuple t ts x =
       let loc = t.ptyp_loc in
       let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = t } in
       let n = List.length ts in
       let p, es = gen_pat_tuple ~loc "x" n in
       pexp_match ~loc x
         [ p --> derive_of_tuple self#derive_of_core_type t es ]

     method! derive_of_record td fs x =
       let t =
         { rcd_loc = td.ptype_loc; rcd_fields = fs; rcd_ctx = td }
       in
       let loc = td.ptype_loc in
       let p, es = gen_pat_record ~loc "x" fs in
       pexp_match ~loc x
         [ p --> derive_of_record self#derive_of_core_type t es ]

     method! derive_of_labeled_tuple t ts x =
       let fs =
         List.map ts ~f:(fun (name, type_) ->
             let loc = type_.ptyp_loc in
             label_declaration ~loc ~name ~type_ ~mutable_:Immutable)
       in
       let loc = t.ptyp_loc in
       let t = { rcd_loc = t.ptyp_loc; rcd_fields = fs; rcd_ctx = () } in
       let p, es = gen_pat_labeled_tuple ~loc "x" ts in
       pexp_match ~loc x
         [ p --> derive_of_labeled_tuple self#derive_of_core_type t es ]

     method! derive_of_variant td cs x =
       let loc = td.ptype_loc in
       let compact = Attrs.Json.is_compact_variants td in
       let ctor_pat (n : label loc) pat =
         ppat_construct ~loc:n.loc (map_loc lident n) pat
       in
       let cs = repr_variant_cases cs in
       pexp_match ~loc x
         (List.rev_map cs ~f:(fun c ->
              let n = c.pcd_name in
              let ctx = `Variant_ctx c in
              match c.pcd_args with
              | Pcstr_record fs ->
                  let p, es = gen_pat_record ~loc "x" fs in
                  let t =
                    let t =
                      { rcd_loc = loc; rcd_fields = fs; rcd_ctx = ctx }
                    in
                    Vcs_record (n, t)
                  in
                  ctor_pat n (Some p)
                  --> derive_of_variant_case ~is_compact_variants:compact
                        self#derive_of_core_type t es
              | Pcstr_tuple ts ->
                  let arity = List.length ts in
                  let t =
                    let t =
                      { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx }
                    in
                    Vcs_tuple (n, t)
                  in
                  let p, es = gen_pat_tuple ~loc "x" arity in
                  ctor_pat n (if arity = 0 then None else Some p)
                  --> derive_of_variant_case ~is_compact_variants:compact
                        self#derive_of_core_type t es))

     method! derive_of_polyvariant ?td t (cs : row_field list) x =
       let loc = t.ptyp_loc in
       let compact =
         Option.fold ~none:false ~some:Attrs.Json.is_compact_variants td
       in
       let cases = repr_polyvariant_cases cs in
       let cases =
         List.rev_map cases ~f:(fun (c, r) ->
             let ctx = `Polyvariant_ctx c in
             match r with
             | `Rtag (n, []) ->
                 let t =
                   let t =
                     { tpl_loc = loc; tpl_types = []; tpl_ctx = ctx }
                   in
                   Vcs_tuple (n, t)
                 in
                 ppat_variant ~loc n.txt None
                 --> derive_of_variant_case ~is_compact_variants:compact
                       self#derive_of_core_type t []
             | `Rtag (n, ts) ->
                 let t =
                   { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx }
                 in
                 let ps, es = gen_pat_tuple ~loc "x" (List.length ts) in
                 ppat_variant ~loc n.txt (Some ps)
                 --> derive_of_variant_case ~is_compact_variants:compact
                       self#derive_of_core_type
                       (Vcs_tuple (n, t))
                       es
             | `Rinherit (n, ts) ->
                 [%pat? [%p ppat_type ~loc n] as x]
                 --> self#derive_of_core_type
                       (ptyp_constr ~loc:n.loc n ts)
                       [%expr x])
       in
       pexp_match ~loc x cases
   end
    :> deriving)
