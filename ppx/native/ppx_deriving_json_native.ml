open Printf
open StdLabels
open Ppxlib
open Ast_builder.Default
open Ast_helpers
open Conv
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

  let build_tuple ~loc derive es ts =
    let args =
      List.fold_left
        (List.rev (List.combine es ts))
        ~init:[]
        ~f:(fun prev (x, t) ->
          let this = derive t x in
          this :: prev)
    in
    pexp_tuple ~loc args

  let build_record ~allow_extra_fields ~loc derive fs x make =
    with_refs ~loc "x" fs @@ fun ename ->
    let handle_field k v =
      let fail_case =
        if allow_extra_fields then [%pat? _] --> [%expr ()]
        else
          [%pat? name]
          --> [%expr
                Melange_json.of_json_error ~json:x
                  (Stdlib.Printf.sprintf {|did not expect field "%s"|}
                     name)]
      in
      let cases =
        List.fold_left (List.rev fs) ~init:[ fail_case ]
          ~f:(fun next ld ->
            let key =
              Option.value ~default:ld.pld_name
                (Attrs.Json.ld_attr_json_key ld)
            in
            pstring ~loc:key.loc key.txt
            --> [%expr
                  [%e ename ld.pld_name] :=
                    Stdlib.Option.Some [%e derive ld.pld_type v]]
            :: next)
      in
      pexp_match ~loc k cases
    in
    let build =
      let fields =
        List.map fs ~f:(fun ld ->
            let key =
              Option.value ~default:ld.pld_name
                (Attrs.Json.ld_attr_json_key ld)
            in
            let default = ld_attr_default ld in
            ( ld.pld_name,
              [%expr
                match Stdlib.( ! ) [%e ename ld.pld_name] with
                | Stdlib.Option.Some v -> v
                | Stdlib.Option.None ->
                    [%e
                      match default with
                      | Some default -> default
                      | None ->
                          [%expr
                            Melange_json.of_json_error ~json:x
                              [%e
                                estring ~loc:key.loc
                                  (sprintf "expected field %S" key.txt)]]]]
            ))
      in
      make ~loc fields
    in
    [%expr
      let rec iter = function
        | [] -> ()
        | (n', v) :: fs ->
            [%e handle_field [%expr n'] [%expr v]];
            iter fs
      in
      iter [%e x];
      [%e build]]

  let derive_of_tuple derive t x =
    let loc = t.tpl_loc in
    let n = List.length t.tpl_types in
    let xpatt, xexprs = gen_pat_list ~loc "x" n in
    let xpatt = [%pat? `List [%p xpatt]] in
    pexp_match ~loc x
      [
        xpatt --> build_tuple ~loc derive xexprs t.tpl_types;
        [%pat? _]
        --> [%expr
              Melange_json.of_json_error ~json:[%e x]
                [%e
                  estring ~loc
                    (sprintf "expected a JSON array of length %i" n)]];
      ]

  let derive_of_record' ~allow_extra_fields ~make derive t x =
    let loc = t.rcd_loc in
    pexp_match ~loc x
      [
        [%pat? `Assoc fs]
        --> build_record ~allow_extra_fields ~loc derive t.rcd_fields
              [%expr fs] make;
        [%pat? _]
        --> [%expr
              Melange_json.of_json_error ~json:[%e x]
                [%e estring ~loc (sprintf "expected a JSON object")]];
      ]

  let derive_of_record derive t x =
    let allow_extra_fields = td_allow_extra_fields t.rcd_ctx in
    let make ~loc fs =
      let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
      pexp_record ~loc fs None
    in
    derive_of_record' ~allow_extra_fields ~make derive t x

  let derive_of_labeled_tuple derive t x =
    let make ~loc fs =
      let fs =
        List.map fs ~f:(fun (n, v) -> labeled_tuple_arg_label n, v)
      in
      pexp_labeled_tuple ~loc fs
    in
    derive_of_record' ~allow_extra_fields:true ~make derive t x

  let derive_of_variant_case ?(is_compact_variants = false) derive make
      vcs =
    match vcs with
    | Vcs_tuple (n, t) when vcs_attr_json_allow_any t.tpl_ctx ->
        let loc = n.loc in
        [%pat? _] --> make (Some [%expr x])
    | Vcs_tuple (n, t) when vcs_attr_json_catch_all t.tpl_ctx -> (
        let loc = n.loc in
        match t.tpl_types with
        | [ _ ] ->
            [%pat? (`String _ | `List (`String _ :: _)) as v]
            --> [%expr
                  let tag =
                    match v with
                    | `String s -> s
                    | `List (`String s :: _) -> s
                    | _ -> assert false
                  in
                  let payload =
                    match v with
                    | `String _ -> Stdlib.Option.None
                    | `List (_ :: rest) -> Stdlib.Option.Some rest
                    | _ -> assert false
                  in
                  [%e
                    make
                      (Some
                         [%expr
                           ({ tag; payload }
                             : Melange_json.unknown_variant_case)])]]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] requires exactly one argument: a record \
               type with fields `tag : string` and `payload : \
               Yojson.Basic.t list option` (typically \
               [Melange_json.unknown_variant_case])")
    | Vcs_record (_n, t) when vcs_attr_json_catch_all t.rcd_ctx -> (
        let loc = t.rcd_loc in
        match t.rcd_fields with
        | [
         { pld_name = { txt = "tag"; _ }; _ };
         { pld_name = { txt = "payload"; _ }; _ };
        ] ->
            [%pat? (`String _ | `List (`String _ :: _)) as v]
            --> [%expr
                  let tag =
                    match v with
                    | `String s -> s
                    | `List (`String s :: _) -> s
                    | _ -> assert false
                  in
                  let payload =
                    match v with
                    | `String _ -> Stdlib.Option.None
                    | `List (_ :: rest) -> Stdlib.Option.Some rest
                    | _ -> assert false
                  in
                  [%e
                    make
                      (Some
                         [%expr
                           ({ tag; payload }
                             : Melange_json.unknown_variant_case)])]]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] inline record must have exactly two \
               fields named `tag` and `payload` (in that order), with \
               types `string` and `Yojson.Basic.t list option`")
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        let arity = List.length t.tpl_types in
        if is_compact_variants && arity = 0 then
          [%pat?
            ( `String [%p pstring ~loc:n.loc n.txt]
            | `List [ `String [%p pstring ~loc:n.loc n.txt] ] )]
          --> make None
        else if arity = 0 then
          [%pat? `List [ `String [%p pstring ~loc:n.loc n.txt] ]]
          --> make None
        else
          let xpatt, xexprs = gen_pat_list ~loc "x" arity in
          [%pat?
            `List (`String [%p pstring ~loc:n.loc n.txt] :: [%p xpatt])]
          --> make (Some (build_tuple ~loc derive xexprs t.tpl_types))
    | Vcs_record (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.rcd_ctx) in
        let allow_extra_fields =
          match t.rcd_ctx with
          | `Variant_ctx cd -> cd_allow_extra_fields cd
          | `Polyvariant_ctx _ -> true
        in
        [%pat? `List [ `String [%p pstring ~loc:n.loc n.txt]; `Assoc fs ]]
        --> build_record ~allow_extra_fields ~loc derive t.rcd_fields
              [%expr fs] (fun ~loc fs ->
                let fs =
                  List.map fs ~f:(fun (n, v) -> map_loc lident n, v)
                in
                make (Some (pexp_record ~loc fs None)))

  (* Sort key for variant cases. Smaller = visited earlier by the
     fold-left in [deriving_of_match], which means it ends up *later* in
     the generated [match …] cases (the fold prepends). So we want the
     widest catch-alls to come first here:
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

  let deriving : Conv.deriving =
    deriving_of_match () ~name:"of_json"
      ~of_t:(fun ~loc -> [%type: Yojson.Basic.t])
      ~cmp_sort_vcs ~derive_of_tuple ~derive_of_labeled_tuple
      ~derive_of_record ~derive_of_variant_case
end

module To_json = struct
  let gen_exp_pat ~loc prefix =
    let n = gen_symbol ~prefix () in
    evar ~loc n, pvar ~loc n

  let derive_of_tuple derive t es =
    let loc = t.tpl_loc in
    let es = List.map2 t.tpl_types es ~f:derive in
    [%expr `List [%e elist ~loc es]]

  let derive_of_record derive t es =
    let loc = t.rcd_loc in
    let ebnds, pbnds = gen_exp_pat ~loc "bnds" in
    let e =
      List.combine t.rcd_fields es
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
                  if Melange_json.equal json [%e derive ld.pld_type def]
                  then [%e ebnds]
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
    | Vcs_tuple (_n, t) when vcs_attr_json_allow_any t.tpl_ctx -> (
        match es with
        | [ x ] -> x
        | es ->
            failwith
              (sprintf "expected a tuple of length 1, got %i"
                 (List.length es)))
    | Vcs_tuple (n, t) when vcs_attr_json_catch_all t.tpl_ctx -> (
        let loc = n.loc in
        match t.tpl_types, es with
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
               [Melange_json.unknown_variant_case])")
    | Vcs_record (_n, t) when vcs_attr_json_catch_all t.rcd_ctx -> (
        let loc = t.rcd_loc in
        match t.rcd_fields, es with
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
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        let arity = List.length t.tpl_types in
        if is_compact_variants && arity = 0 then
          [%expr `String [%e estring ~loc:n.loc n.txt]]
        else
          [%expr
            `List
              (`String [%e estring ~loc:n.loc n.txt]
              :: [%e elist ~loc (List.map2 t.tpl_types es ~f:derive)])]
    | Vcs_record (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.rcd_ctx) in
        [%expr
          `List
            (`String [%e estring ~loc:n.loc n.txt]
            :: [ [%e derive_of_record derive t es] ])]

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
