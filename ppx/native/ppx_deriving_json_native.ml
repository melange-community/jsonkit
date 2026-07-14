open Printf
open StdLabels
open Ppxlib
open Ast_builder.Default
open Ast_helpers
open Conv
open Conv.Variant
open Attrs.Json
open Json_string_deriver

module Of_json = struct
  let with_refs ~loc prefix fs inner =
    let gen_name n = sprintf "%s_%s" prefix n in
    let gen_expr (n : label loc) =
      pexp_ident ~loc:n.loc { loc = n.loc; txt = lident (gen_name n.txt) }
    in
    List.fold_left (List.rev fs) ~init:(inner gen_expr) ~f:(fun next ld ->
        let n = ld.pld_name in
        let patt =
          ppat_var ~loc:n.loc { loc = n.loc; txt = gen_name n.txt }
        in
        [%expr
          let [%p patt] =
            ref
              [%e
                match ld_attr_default ld with
                | Some default -> [%expr Stdlib.Option.Some [%e default]]
                | None -> [%expr Stdlib.Option.None]]
          in
          [%e next]])

  let build_tuple ~loc of_json values types =
    let args =
      List.fold_left
        (List.rev (List.combine values types))
        ~init:[]
        ~f:(fun prev (value, type_) ->
          let this = of_json type_ value in
          this :: prev)
    in
    pexp_tuple ~loc args

  let build_record ~loc ~allow_extra_fields ~json_fields of_json
      fields_label make =
    with_refs ~loc "x" fields_label @@ fun ename ->
    let field_key ld =
      Option.value ~default:ld.pld_name (Attrs.Json.ld_attr_json_key ld)
    in
    let store_case value ld =
      let key = field_key ld in
      pstring ~loc:key.loc key.txt
      --> [%expr
            [%e ename ld.pld_name] :=
              Stdlib.Option.Some [%e of_json ld.pld_type value]]
    in
    let fail_case =
      if allow_extra_fields then [%pat? _] --> [%expr ()]
      else
        [%pat? name]
        --> [%expr
              Jsonkit.of_json_error ~json:x
                (Stdlib.Printf.sprintf {|did not expect field "%s"|} name)]
    in
    let handle_field key value =
      pexp_match ~loc key
        (List.map fields_label ~f:(store_case value) @ [ fail_case ])
    in
    let read_field ld =
      let key = field_key ld in
      let fallback =
        match ld_attr_default ld with
        | Some default -> default
        | None ->
            [%expr
              Jsonkit.of_json_error ~json:x
                [%e
                  estring ~loc:key.loc
                    (sprintf "expected field %S" key.txt)]]
      in
      ( ld.pld_name,
        [%expr
          match Stdlib.( ! ) [%e ename ld.pld_name] with
          | Stdlib.Option.Some v -> v
          | Stdlib.Option.None -> [%e fallback]] )
    in
    let built = make ~loc (List.map fields_label ~f:read_field) in
    [%expr
      let rec iter = function
        | [] -> ()
        | (n', v) :: fs ->
            [%e handle_field [%expr n'] [%expr v]];
            iter fs
      in
      iter [%e json_fields];
      [%e built]]

  let derive_of_tuple ~loc of_json ts json =
    let length = List.length ts in
    let xpatt, xexprs = gen_pat_list ~loc "x" length in
    let tuple_types = ts in
    pexp_match ~loc json
      [
        [%pat? `List [%p xpatt]]
        --> build_tuple ~loc of_json xexprs tuple_types;
        [%pat? _]
        --> [%expr
              Jsonkit.of_json_error ~json:[%e json]
                [%e
                  estring ~loc
                    (sprintf "expected a JSON array of length %i" length)]];
      ]

  let derive_of_record' ~loc ~allow_extra_fields ~build of_json fields x =
    pexp_match ~loc x
      [
        [%pat? `Assoc fs]
        --> build_record ~allow_extra_fields ~json_fields:[%expr fs] ~loc
              of_json fields build;
        [%pat? _]
        --> [%expr
              Jsonkit.of_json_error ~json:[%e x]
                [%e estring ~loc (sprintf "expected a JSON object")]];
      ]

  let derive_of_record ~loc ~allow_extra_fields derive fields x =
    let build ~loc fs =
      let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
      pexp_record ~loc fs None
    in
    derive_of_record' ~loc ~allow_extra_fields ~build derive fields x

  let derive_of_labeled_tuple ~loc derive fields x =
    let build ~loc fs =
      let fs =
        List.map fs ~f:(fun (n, v) -> labeled_tuple_arg_label n, v)
      in
      pexp_labeled_tuple ~loc fs
    in
    derive_of_record' ~loc ~allow_extra_fields:true ~build derive fields x

  let derive_of_variant_case ?(is_compact_variants = false) of_json
      construct case =
    match case with
    | Vcs_tuple { name; attr = { allow_any = true; _ }; _ } ->
        let loc = name.loc in
        [%pat? _] --> construct (Some [%expr x])
    | Vcs_tuple { name; types; attr = { catch_all = true; _ }; _ } -> (
        let loc = name.loc in
        match types with
        | [ _ ] ->
            [%pat? (`String _ | `List (`String _ :: _)) as v]
            --> [%expr
                  let tag, payload =
                    match v with
                    | `String s -> s, Stdlib.Option.None
                    | `List (`String s :: payload) ->
                        s, Stdlib.Option.Some payload
                    | _ -> assert false
                  in
                  [%e
                    construct
                      (Some
                         [%expr
                           ({ tag; payload }
                             : Jsonkit.unknown_variant_case)])]]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] requires exactly one argument: a record \
               type with fields `tag : string` and `payload : \
               Yojson.Basic.t list option` (typically \
               [Jsonkit.unknown_variant_case])")
    | Vcs_record { loc; fields; attr = { catch_all = true; _ }; _ } -> (
        match fields with
        | [
         { pld_name = { txt = "tag"; _ }; _ };
         { pld_name = { txt = "payload"; _ }; _ };
        ] ->
            [%pat? (`String _ | `List (`String _ :: _)) as v]
            --> [%expr
                  let tag, payload =
                    match v with
                    | `String s -> s, Stdlib.Option.None
                    | `List (`String s :: payload) ->
                        s, Stdlib.Option.Some payload
                    | _ -> assert false
                  in
                  [%e
                    construct
                      (Some
                         [%expr
                           ({ tag; payload }
                             : Jsonkit.unknown_variant_case)])]]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] inline record must have exactly two \
               fields named `tag` and `payload` (in that order), with \
               types `string` and `Yojson.Basic.t list option`")
    | Vcs_tuple { name; types; attr; _ } ->
        let loc = name.loc in
        let n = Option.value ~default:name attr.json_name in
        let arity = List.length types in
        if is_compact_variants && arity = 0 then
          [%pat?
            ( `String [%p pstring ~loc:n.loc n.txt]
            | `List [ `String [%p pstring ~loc:n.loc n.txt] ] )]
          --> construct None
        else if arity = 0 then
          [%pat? `List [ `String [%p pstring ~loc:n.loc n.txt] ]]
          --> construct None
        else
          let xpatt, xexprs = gen_pat_list ~loc "x" arity in
          [%pat?
            `List (`String [%p pstring ~loc:n.loc n.txt] :: [%p xpatt])]
          --> construct (Some (build_tuple ~loc of_json xexprs types))
    | Vcs_record { name; loc; fields; attr; allow_extra_fields } ->
        let n = Option.value ~default:name attr.json_name in
        [%pat? `List [ `String [%p pstring ~loc:n.loc n.txt]; `Assoc fs ]]
        --> build_record ~allow_extra_fields ~loc ~json_fields:[%expr fs]
              of_json fields (fun ~loc fs ->
                let fs =
                  List.map fs ~f:(fun (n, v) -> map_loc lident n, v)
                in
                construct (Some (pexp_record ~loc fs None)))

  (* Sort key for variant cases. Smaller = visited earlier by the
     fold-left in [derive_of_variant]/[derive_of_polyvariant] below, which
     means it ends up *later* in the generated [match …] cases (the fold
     prepends). So we want the widest catch-alls to come first here:
       - [@json.allow_any] (catches any JSON)
       - [@json.catch_all] (catches any string)
       - specific constructor cases
   *)
  let cmp_sort_vcs vcs1 vcs2 =
    let key vcs =
      if vcs_attr_json_allow_any vcs then 0
      else if vcs_attr_json_catch_all vcs then 1
      else 2
    in
    compare (key vcs1) (key vcs2)

  (* of_json for native: JSON is [Yojson.Basic.t], a matchable ADT, so the
     variant decoder is a single [match] expression. This object plugs the
     module-local leaf builders into the shared [Conv.deriving1] traversal;
     [cmp_sort_vcs] orders the arms so the widest catch-alls come first. *)
  let deriving : Conv.deriving =
    (object (self)
       inherit deriving1
       method name = "of_json"
       method t ~loc _name t = [%type: Yojson.Basic.t -> [%t t]]

       method! derive_of_tuple t ts x =
         derive_of_tuple ~loc:t.ptyp_loc self#derive_of_core_type ts x

       method! derive_of_labeled_tuple t ts x =
         let fs =
           List.map ts ~f:(fun (name, type_) ->
               let loc = type_.ptyp_loc in
               label_declaration ~loc ~name ~type_ ~mutable_:Immutable)
         in
         derive_of_labeled_tuple ~loc:t.ptyp_loc self#derive_of_core_type
           fs x

       method! derive_of_record td fs x =
         derive_of_record ~loc:td.ptype_loc
           ~allow_extra_fields:(Attrs.Json.td_allow_extra_fields td)
           self#derive_of_core_type fs x

       method! derive_of_variant td cs x =
         let loc = td.ptype_loc in
         let compact = Attrs.Json.is_compact_variants td in
         let error_message =
           Printf.sprintf "expected %s"
             (get_constructor_names ~compact cs
             |> String.concat ~sep:" or ")
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
               let construct (n : label loc) arg =
                 pexp_construct (map_loc lident n) ~loc:n.loc arg
               in
               let n = c.pcd_name in
               let attr = resolve_attr (`Variant_ctx c) in
               match c.pcd_args with
               | Pcstr_record fields ->
                   let case =
                     Vcs_record
                       {
                         name = n;
                         loc;
                         fields;
                         attr;
                         allow_extra_fields =
                           Attrs.Json.cd_allow_extra_fields c;
                       }
                   in
                   derive_of_variant_case self#derive_of_core_type
                     ~is_compact_variants:compact (construct n) case
                   :: next
               | Pcstr_tuple types ->
                   let case = Vcs_tuple { name = n; loc; types; attr } in
                   derive_of_variant_case self#derive_of_core_type
                     ~is_compact_variants:compact (construct n) case
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
               let attr = resolve_attr (`Polyvariant_ctx c) in
               match r with
               | `Rtag (n, ts) ->
                   Left (n, Vcs_tuple { name = n; loc; types = ts; attr })
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
                   let maybe =
                     self#derive_type_ref ~loc self#name n ts x
                   in
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
             ~f:(fun next ((n : label loc), case) ->
               let construct arg = pexp_variant ~loc:n.loc n.txt arg in
               derive_of_variant_case ~is_compact_variants:compact
                 self#derive_of_core_type construct case
               :: next)
         in
         pexp_match ~loc x cases
     end
      :> Conv.deriving)
end

module To_json = struct
  let gen_exp_pat ~loc prefix =
    let n = gen_symbol ~prefix () in
    evar ~loc n, pvar ~loc n

  let derive_of_tuple ~loc derive types es =
    let es = List.map2 types es ~f:derive in
    [%expr `List [%e elist ~loc es]]

  let derive_of_record ~loc derive fields es =
    let ebnds, pbnds = gen_exp_pat ~loc "bnds" in
    let e =
      List.combine fields es
      |> List.fold_left ~init:ebnds ~f:(fun acc (ld, x) ->
          let key =
            Option.value ~default:ld.pld_name
              (Attrs.Json.ld_attr_json_key ld)
          in
          let k = estring ~loc:key.loc key.txt in
          let v = derive ld.pld_type x in
          let ebnds =
            match ld_drop_default ld with
            | `No -> [%expr ([%e k], [%e v]) :: [%e ebnds]]
            | `Drop_option ->
                [%expr
                  match [%e x] with
                  | Stdlib.Option.None -> [%e ebnds]
                  | Stdlib.Option.Some _ -> ([%e k], [%e v]) :: [%e ebnds]]
            | `Drop_default (cmp, def) ->
                [%expr
                  if [%e cmp] [%e x] [%e def] then [%e ebnds]
                  else ([%e k], [%e v]) :: [%e ebnds]]
            | `Drop_default_if_json_equal def ->
                [%expr
                  let json = [%e v] in
                  if Jsonkit.equal json [%e derive ld.pld_type def] then
                    [%e ebnds]
                  else ([%e k], json) :: [%e ebnds]]
          in
          [%expr
            let [%p pbnds] = [%e ebnds] in
            [%e acc]])
    in
    [%expr
      `Assoc
        (let [%p pbnds] = [] in
         [%e e])]

  let derive_of_variant_case ?(is_compact_variants = false) derive vcs es
      =
    match vcs with
    | Vcs_tuple { attr = { allow_any = true; _ }; _ } -> (
        match es with
        | [ x ] -> x
        | es ->
            failwith
              (sprintf "expected a tuple of length 1, got %i"
                 (List.length es)))
    | Vcs_tuple { name; types; attr = { catch_all = true; _ }; _ } -> (
        let loc = name.loc in
        match types, es with
        | [ _ ], [ arg_e ] ->
            [%expr
              match [%e arg_e].payload with
              | Stdlib.Option.None -> `String [%e arg_e].tag
              | Stdlib.Option.Some xs ->
                  `List (`String [%e arg_e].tag :: xs)]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] requires exactly one argument: a record \
               type with fields `tag : string` and `payload : \
               Yojson.Basic.t list option` (typically \
               [Jsonkit.unknown_variant_case])")
    | Vcs_record { loc; fields; attr = { catch_all = true; _ }; _ } -> (
        match fields, es with
        | ( [
              { pld_name = { txt = "tag"; _ }; _ };
              { pld_name = { txt = "payload"; _ }; _ };
            ],
            [ tag_e; payload_e ] ) ->
            [%expr
              match [%e payload_e] with
              | Stdlib.Option.None -> `String [%e tag_e]
              | Stdlib.Option.Some xs -> `List (`String [%e tag_e] :: xs)]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] inline record must have exactly two \
               fields named `tag` and `payload` (in that order), with \
               types `string` and `Yojson.Basic.t list option`")
    | Vcs_tuple { name; types; attr; _ } ->
        let loc = name.loc in
        let n = Option.value ~default:name attr.json_name in
        let arity = List.length types in
        if is_compact_variants && arity = 0 then
          [%expr `String [%e estring ~loc:n.loc n.txt]]
        else
          [%expr
            `List
              (`String [%e estring ~loc:n.loc n.txt]
              :: [%e elist ~loc (List.map2 types es ~f:derive)])]
    | Vcs_record { name; loc; fields; attr; _ } ->
        let n = Option.value ~default:name attr.json_name in
        [%expr
          `List
            (`String [%e estring ~loc:n.loc n.txt]
            :: [ [%e derive_of_record ~loc derive fields es] ])]

  let deriving : Conv.deriving =
    deriving_to () ~name:"to_json"
      ~t_to:(fun ~loc -> [%type: Yojson.Basic.t])
      ~derive_of_tuple ~derive_of_labeled_tuple:derive_of_record
      ~derive_of_record ~derive_of_variant_case
end

let () =
  let of_json = Conv.register Of_json.deriving in
  let to_json = Conv.register To_json.deriving in
  let (json : Deriving.t) =
    Conv.(register_combined "json" [ To_json.deriving; Of_json.deriving ])
  in
  let (_ : Deriving.t) = Of_json_string.register ~of_json () in
  let (_ : Deriving.t) = To_json_string.register ~to_json () in
  let (_ : Deriving.t) = Json_string.register ~json () in
  let (_ : Deriving.t) = Ppx_deriving_jsonschema.register () in
  Linter.register ()
