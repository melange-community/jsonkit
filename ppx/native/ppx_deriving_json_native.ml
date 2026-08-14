open Printf
open StdLabels
open Ppxlib
open Ast_builder.Default
open Ast_helpers
open Conv
open Json_string_deriver

module Of_json = struct
  let with_refs ~loc prefix fs inner =
    let gen_name n = sprintf "%s_%s" prefix n in
    let gen_expr (n : label loc) =
      pexp_ident ~loc:n.loc { loc = n.loc; txt = lident (gen_name n.txt) }
    in
    List.fold_left (List.rev fs) ~init:(inner gen_expr)
      ~f:(fun next (f : Record.field) ->
        let n = f.name in
        let patt =
          ppat_var ~loc:n.loc { loc = n.loc; txt = gen_name n.txt }
        in
        [%expr
          let [%p patt] =
            ref
              [%e
                match f.default with
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

  let build_record ~loc ~json_fields of_json (record : Record.t) make =
    let fields = record.fields in
    with_refs ~loc "x" fields @@ fun ename ->
    let store_case value (f : Record.field) =
      let key = f.key in
      pstring ~loc:key.loc key.txt
      --> [%expr
            [%e ename f.name] :=
              Stdlib.Option.Some [%e of_json f.type_ value]]
    in
    let fail_case =
      if record.allow_extra_fields then [%pat? _] --> [%expr ()]
      else
        [%pat? name]
        --> [%expr
              Jsonkit.of_json_error ~json:x
                (Stdlib.Printf.sprintf {|did not expect field "%s"|} name)]
    in
    let handle_field key value =
      pexp_match ~loc key
        (List.map fields ~f:(store_case value) @ [ fail_case ])
    in
    let read_field (f : Record.field) =
      let key = f.key in
      let fallback =
        match f.default with
        | Some default -> default
        | None ->
            [%expr
              Jsonkit.of_json_error ~json:x
                [%e
                  estring ~loc:key.loc
                    (sprintf "expected field %S" key.txt)]]
      in
      ( f.name,
        [%expr
          match Stdlib.( ! ) [%e ename f.name] with
          | Stdlib.Option.Some v -> v
          | Stdlib.Option.None -> [%e fallback]] )
    in
    let built = make ~loc (List.map fields ~f:read_field) in
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
    pexp_match ~loc json
      [
        [%pat? `List [%p xpatt]] --> build_tuple ~loc of_json xexprs ts;
        [%pat? _]
        --> [%expr
              Jsonkit.of_json_error ~json:[%e json]
                [%e
                  estring ~loc
                    (sprintf "expected a JSON array of length %i" length)]];
      ]

  let derive_of_record' ~loc ~build of_json record x =
    pexp_match ~loc x
      [
        [%pat? `Assoc fs]
        --> build_record ~json_fields:[%expr fs] ~loc of_json record build;
        [%pat? _]
        --> [%expr
              Jsonkit.of_json_error ~json:[%e x]
                [%e estring ~loc (sprintf "expected a JSON object")]];
      ]

  let derive_of_record ~loc derive record x =
    let build ~loc fs =
      let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
      pexp_record ~loc fs None
    in
    derive_of_record' ~loc ~build derive record x

  let derive_of_labeled_tuple ~loc derive record x =
    let build ~loc fs =
      let fs =
        List.map fs ~f:(fun (n, v) -> labeled_tuple_arg_label n, v)
      in
      pexp_labeled_tuple ~loc fs
    in
    derive_of_record' ~loc ~build derive record x

  let derive_of_variant_case ?(is_compact_variants = false) of_json case =
    let construct = Variant.case_construct case in
    match case with
    | Vcs_tuple { name; attr = { allow_any = true; _ }; _ } ->
        let loc = name.loc in
        [%pat? _] --> construct (Some [%expr x])
    | Vcs_tuple { name; attr = { catch_all = true; _ }; _ }
    | Vcs_record { name; attr = { catch_all = true; _ }; _ } ->
        let loc = name.loc in
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
                       ({ tag; payload } : Jsonkit.unknown_variant_case)])]]
    | Vcs_tuple { name; tag; types; _ } ->
        let loc = name.loc in
        let arity = List.length types in
        if is_compact_variants && arity = 0 then
          [%pat?
            ( `String [%p pstring ~loc:tag.loc tag.txt]
            | `List [ `String [%p pstring ~loc:tag.loc tag.txt] ] )]
          --> construct None
        else if arity = 0 then
          [%pat? `List [ `String [%p pstring ~loc:tag.loc tag.txt] ]]
          --> construct None
        else
          let xpatt, xexprs = gen_pat_list ~loc "x" arity in
          [%pat?
            `List (`String [%p pstring ~loc:tag.loc tag.txt] :: [%p xpatt])]
          --> construct (Some (build_tuple ~loc of_json xexprs types))
    | Vcs_record { tag; loc; record; _ } ->
        [%pat?
          `List [ `String [%p pstring ~loc:tag.loc tag.txt]; `Assoc fs ]]
        --> build_record ~loc ~json_fields:[%expr fs] of_json record
              (fun ~loc fs ->
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
  let case_sort_key case =
    let attr = Variant.case_attr case in
    if attr.allow_any then 0 else if attr.catch_all then 1 else 2

  let cmp_sort_cases c1 c2 = compare (case_sort_key c1) (case_sort_key c2)

  let cmp_sort_pvcs p1 p2 =
    let key = function
      | Variant.Pvc_tag case -> case_sort_key (Vcs_tuple case)
      | Pvc_inherit _ -> 2
    in
    compare (key p1) (key p2)

  (* of_json for native: JSON is [Yojson.Basic.t], a matchable ADT, so the
     variant decoder is a single [match] expression. This object plugs the
     module-local leaf builders into the shared [Conv.deriving_fn] traversal;
     [cmp_sort_vcs] orders the arms so the widest catch-alls come first. *)
  let deriving : Conv.deriving =
    (object (self)
       inherit deriving_fn
       method name = "of_json"
       method t ~loc _name t = [%type: Yojson.Basic.t -> [%t t]]

       method! derive_of_tuple t ts x =
         derive_of_tuple ~loc:t.ptyp_loc self#derive_of_core_type ts x

       method! derive_of_labeled_tuple t ts x =
         derive_of_labeled_tuple ~loc:t.ptyp_loc self#derive_of_core_type
           (Record.of_labeled_tuple ts)
           x

       method! derive_of_record td fs x =
         derive_of_record ~loc:td.ptype_loc self#derive_of_core_type
           (Record.of_type_declaration td fs)
           x

       method! derive_of_variant td cs x =
         let loc = td.ptype_loc in
         let { Variant.compact; cases; _ } =
           Variant.resolve_variant td cs
         in
         let error_message =
           Variant.expected_message
             (List.map cases ~f:(Variant.case_json_shape ~compact))
         in
         let cases =
           List.stable_sort ~cmp:cmp_sort_cases (List.rev cases)
         in
         let cases =
           List.fold_left cases
             ~init:
               [
                 [%pat? _]
                 --> [%expr
                       Jsonkit.of_json_error ~json:x
                         [%e estring ~loc error_message]];
               ]
             ~f:(fun next case ->
               derive_of_variant_case self#derive_of_core_type
                 ~is_compact_variants:compact case
               :: next)
         in
         pexp_match ~loc x cases

       method! derive_of_polyvariant ?td t (cs : row_field list) x =
         let loc = t.ptyp_loc in
         let { Variant.compact; pvcs; _ } =
           Variant.resolve_polyvariant ?td cs
         in
         let error_message =
           Variant.expected_message
             (Variant.polyvariant_json_shapes ~compact ~loc pvcs)
         in
         let cases =
           List.stable_sort ~cmp:cmp_sort_pvcs (List.rev pvcs)
         in
         let ctors, inherits =
           List.partition_map cases ~f:(function
             | Variant.Pvc_tag case -> Left (Variant.Vcs_tuple case)
             | Pvc_inherit (n, ts) -> Right (n, ts))
         in
         let catch_all =
           [%pat? x]
           --> List.fold_left (List.rev inherits)
                 ~init:
                   [%expr
                     Jsonkit.of_json_unexpected_variant ~json:x
                       [%e estring ~loc error_message]]
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
           List.fold_left ctors ~init:[ catch_all ] ~f:(fun next case ->
               derive_of_variant_case ~is_compact_variants:compact
                 self#derive_of_core_type case
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

  let json_array ~loc es = [%expr `List [%e elist ~loc es]]

  let json_string ~loc (n : label loc) =
    [%expr `String [%e estring ~loc:n.loc n.txt]]

  let catch_all_encode ~loc ~tag ~payload =
    [%expr
      match [%e payload] with
      | Stdlib.Option.None -> `String [%e tag]
      | Stdlib.Option.Some xs -> `List (`String [%e tag] :: xs)]

  let derive_of_record ~loc derive fields es =
    let ebnds, pbnds = gen_exp_pat ~loc "bnds" in
    let e =
      List.combine fields es
      |> List.fold_left ~init:ebnds
           ~f:(fun acc ((f : Record.to_field), x) ->
             let k = estring ~loc:f.key.loc f.key.txt in
             let v = derive f.type_ x in
             let ebnds =
               match f.drop with
               | `No -> [%expr ([%e k], [%e v]) :: [%e ebnds]]
               | `Drop_option ->
                   [%expr
                     match [%e x] with
                     | Stdlib.Option.None -> [%e ebnds]
                     | Stdlib.Option.Some _ ->
                         ([%e k], [%e v]) :: [%e ebnds]]
               | `Drop_default (cmp, def) ->
                   [%expr
                     if [%e cmp] [%e x] [%e def] then [%e ebnds]
                     else ([%e k], [%e v]) :: [%e ebnds]]
               | `Drop_default_if_json_equal def ->
                   [%expr
                     let json = [%e v] in
                     if Jsonkit.equal json [%e derive f.type_ def] then
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

  let deriving : Conv.deriving =
    deriving_to () ~name:"to_json"
      ~t_to:(fun ~loc -> [%type: Yojson.Basic.t])
      ~json_array ~json_string ~catch_all_encode ~derive_of_record
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
