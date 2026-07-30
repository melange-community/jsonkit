open Printf
open StdLabels
open Ppxlib
open Ast_builder.Default
open Ast_helpers
open Conv
open Attrs.Json
open Json_string_deriver

module Of_json = struct
  let build_tuple ~loc derive si (ts : core_type list) e =
    pexp_tuple ~loc
      (List.mapi ts ~f:(fun i t ->
           derive t
             [%expr Js.Array.unsafe_get [%e e] [%e eint ~loc (si + i)]]))

  let build_js_type ~loc (fs : label_declaration list) =
    let f ld =
      let n = ld.pld_name in
      let n = Option.value ~default:n (Attrs.Json.ld_attr_json_key ld) in
      let pof_desc = Otag (n, [%type: Js.Json.t Js.undefined]) in
      { pof_loc = loc; pof_attributes = []; pof_desc }
    in
    let row = ptyp_object ~loc (List.map fs ~f) Closed in
    [%type: [%t row] Js.t]

  let build_record ~allow_extra_fields ~loc derive
      (fs : label_declaration list) x make =
    let field_key ld =
      let n = ld.pld_name in
      Option.value ~default:n (Attrs.Json.ld_attr_json_key ld)
    in
    let handle_field fs ld =
      ( ld.pld_name,
        let n = field_key ld in
        [%expr
          match
            Js.Undefined.toOption
              [%e fs]##[%e pexp_ident ~loc:n.loc (map_loc lident n)]
          with
          | Stdlib.Option.Some v -> [%e derive ld.pld_type [%expr v]]
          | Stdlib.Option.None ->
              [%e
                match ld_attr_default ld with
                | Some default -> default
                | None ->
                    [%expr
                      Melange_json.of_json_error ~json:x
                        [%e
                          estring ~loc
                            (sprintf "expected field %S to be present"
                               n.txt)]]]] )
    in
    let is_known_field name =
      List.fold_left fs ~init:[%expr false] ~f:(fun acc ld ->
          let n = field_key ld in
          [%expr
            Stdlib.( || )
              (Stdlib.( = ) [%e name] [%e estring ~loc:n.loc n.txt])
              [%e acc]])
    in
    let body =
      [%expr
        let fs = (Obj.magic [%e x] : [%t build_js_type ~loc fs]) in
        [%e
          let fs = List.map fs ~f:(handle_field [%expr fs]) in
          make ~loc fs]]
    in
    if allow_extra_fields then body
    else
      [%expr
        let keys =
          Js.Dict.keys (Obj.magic [%e x] : Js.Json.t Js.Dict.t)
        in
        let len = Js.Array.length keys in
        let rec iter i =
          if Stdlib.( < ) i len then
            let name = Js.Array.unsafe_get keys i in
            if [%e is_known_field [%expr name]] then
              iter (Stdlib.( + ) i 1)
            else
              Melange_json.of_json_error ~json:x
                (Stdlib.Printf.sprintf {|did not expect field "%s"|} name)
        in
        iter 0;
        [%e body]]

  let eis_json_object ~loc x =
    [%expr
      Stdlib.( && )
        (Stdlib.( = ) (Js.typeof [%e x]) "object")
        (Stdlib.( && )
           (Stdlib.not (Js.Array.isArray [%e x]))
           (Stdlib.not
              (Stdlib.( == ) (Obj.magic [%e x] : 'a Js.null) Js.null)))]

  let ensure_json_object ~loc x =
    [%expr
      if Stdlib.not [%e eis_json_object ~loc x] then
        Melange_json.of_json_error ~json:[%e x]
          [%e estring ~loc (sprintf "expected a JSON object")]]

  let ensure_json_array_len ~loc ~allow_any_constr ~else_ n len x =
    let error =
      match allow_any_constr with
      | Some allow_any_constr -> allow_any_constr x
      | None ->
          [%expr
            Melange_json.of_json_error ~json:[%e x]
              [%e
                estring ~loc
                  (sprintf "expected a JSON array of length %i" n)]]
    in
    let runtime () =
      [%expr
        if Stdlib.( <> ) [%e len] [%e eint ~loc n] then [%e error]
        else [%e else_]]
    in
    match len.pexp_desc with
    | Pexp_constant (Pconst_integer (s, None)) -> (
        match int_of_string_opt s with
        | Some c -> if c <> n then error else else_
        | None -> runtime ())
    | _ -> runtime ()

  (* True when [len] is a compile-time constant that cannot equal [n]. A
     constructor needing an [n]-element array is then unreachable for this
     input shape — e.g. the bare-string compact form passes a literal [0], so
     no payload constructor can match and we can drop its tag check entirely. *)
  let len_never n len =
    match len.pexp_desc with
    | Pexp_constant (Pconst_integer (s, None)) -> (
        match int_of_string_opt s with Some c -> c <> n | None -> false)
    | _ -> false

  let derive_of_tuple derive t x =
    let loc = t.tpl_loc in
    let n = List.length t.tpl_types in
    [%expr
      if
        Stdlib.( && )
          (Js.Array.isArray [%e x])
          (Stdlib.( = )
             (Js.Array.length (Obj.magic [%e x] : Js.Json.t array))
             [%e eint ~loc n])
      then
        let es = (Obj.magic [%e x] : Js.Json.t array) in
        [%e build_tuple ~loc derive 0 t.tpl_types [%expr es]]
      else
        Melange_json.of_json_error ~json:[%e x]
          [%e
            estring ~loc (sprintf "expected a JSON array of length %i" n)]]

  let derive_of_record derive t x =
    let loc = t.rcd_loc in
    let allow_extra_fields = td_allow_extra_fields t.rcd_ctx in
    let make ~loc fs =
      let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
      pexp_record ~loc fs None
    in
    [%expr
      [%e ensure_json_object ~loc x];
      [%e
        build_record ~allow_extra_fields ~loc derive t.rcd_fields x make]]

  let derive_of_labeled_tuple derive t x =
    let loc = t.rcd_loc in
    let make ~loc fs =
      let fs =
        List.map fs ~f:(fun (n, v) -> labeled_tuple_arg_label n, v)
      in
      pexp_labeled_tuple ~loc fs
    in
    [%expr
      [%e ensure_json_object ~loc x];
      [%e
        build_record ~allow_extra_fields:true ~loc derive t.rcd_fields x
          make]]

  let derive_of_variant ?(is_compact_variants = false) _derive t
      ~allow_any_constr body x =
    let loc = t.vrt_loc in
    let not_array_error =
      match allow_any_constr with
      | Some allow_any_constr -> allow_any_constr x
      | None ->
          [%expr
            Melange_json.of_json_error ~json:[%e x]
              "expected a non empty JSON array"]
    in
    let string_branch =
      if is_compact_variants then
        (* The string form is a bare compact-variant tag: there is no array
           payload, so pass empty [array]/[len] literals straight to [body]
           instead of binding them. An all-nullary variant simply never
           references them (no dummy bindings, no [ignore] needed). *)
        [%expr
          if Stdlib.( = ) (Js.typeof [%e x]) "string" then
            [%e
              body
                ~array:[%expr (Obj.magic [||] : Js.Json.t array)]
                ~len:[%expr 0]
                ~tag:[%expr (Obj.magic [%e x] : string)]]
          else [%e not_array_error]]
      else not_array_error
    in
    [%expr
      if Js.Array.isArray [%e x] then
        let array = (Obj.magic [%e x] : Js.Json.t array) in
        let len = Js.Array.length array in
        if Stdlib.( > ) len 0 then
          let tag = Js.Array.unsafe_get array 0 in
          if Stdlib.( = ) (Js.typeof tag) "string" then
            [%e
              body ~array:[%expr array] ~len:[%expr len]
                ~tag:[%expr (Obj.magic tag : string)]]
          else
            [%e
              match allow_any_constr with
              | Some allow_any_constr -> allow_any_constr x
              | None ->
                  [%expr
                    Melange_json.of_json_error ~json:[%e x]
                      "expected a non empty JSON array with element \
                       being a string"]]
        else [%e not_array_error]
      else [%e string_branch]]

  (* Build a payload-preserving unknown_variant_case value from the already-extracted
     [tag] / [len] / [array] vars (see [derive_of_variant]). Wire shapes:
     bare string ↔ payload=None; single-element array ↔ payload=Some[];
     n-element array ↔ payload=Some(rest). *)
  let build_unknown_variant_case_record ~loc ~tag ~array ~len =
    [%expr
      let tag_s = [%e tag] in
      let payload =
        if Stdlib.( = ) len 0 then Stdlib.Option.None
        else if Stdlib.( = ) len 1 then Stdlib.Option.Some []
        else
          let rest =
            Stdlib.Array.sub [%e array] 1 (Stdlib.( - ) [%e len] 1)
            |> Stdlib.Array.to_list
            |> Stdlib.List.map (fun j -> (Obj.magic j : Melange_json.t))
          in
          Stdlib.Option.Some rest
      in
      ({ tag = tag_s; payload } : Melange_json.unknown_variant_case)]

  let derive_of_variant_case ?(is_compact_variants = false) ~tag ~array
      ~len derive make c ~allow_any_constr next =
    let _ = derive in
    let _ = allow_any_constr in
    match c with
    | Vcs_tuple (n, t) when vcs_attr_json_catch_all t.tpl_ctx -> (
        let loc = n.loc in
        match t.tpl_types with
        | [ _ ] ->
            make (Some (build_unknown_variant_case_record ~loc ~tag))
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] requires exactly one argument: a record \
               type with fields `tag : string` and `payload : \
               Melange_json.t list option` (typically \
               [Melange_json.unknown_variant_case])")
    | Vcs_record (_n, t) when vcs_attr_json_catch_all t.rcd_ctx -> (
        let loc = t.rcd_loc in
        match t.rcd_fields with
        | [
         { pld_name = { txt = "tag"; _ }; _ };
         { pld_name = { txt = "payload"; _ }; _ };
        ] ->
            make (Some (build_unknown_variant_case_record ~loc ~tag))
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] inline record must have exactly two \
               fields named `tag` and `payload` (in that order), with \
               types `string` and `Melange_json.t list option`")
    | Vcs_record (_, _) when len_never 2 len ->
        (* Record variants need [["Name", {...}]] (length 2); unreachable for
           the bare-string form, so skip straight to the next case. *)
        next
    | Vcs_record (n, r) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name r.rcd_ctx) in
        let make ~loc fs =
          let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
          make (Some (fun ~array:_ ~len:_ -> pexp_record ~loc fs None))
        in
        [%expr
          if Stdlib.( = ) [%e tag] [%e estring ~loc:n.loc n.txt] then
            [%e
              ensure_json_array_len ~loc ~allow_any_constr 2 len [%expr x]
                ~else_:
                  [%expr
                    let fs = Js.Array.unsafe_get [%e array] 1 in
                    [%e ensure_json_object ~loc [%expr fs]];
                    [%e
                      let allow_extra_fields =
                        match r.rcd_ctx with
                        | `Variant_ctx cd -> cd_allow_extra_fields cd
                        | `Polyvariant_ctx _ -> true
                      in
                      build_record ~allow_extra_fields ~loc derive
                        r.rcd_fields [%expr fs] make]]]
          else [%e next]]
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        let arity = List.length t.tpl_types in
        if is_compact_variants && arity = 0 then
          [%expr
            if Stdlib.( = ) [%e tag] [%e estring ~loc:n.loc n.txt] then
              [%e make None]
            else [%e next]]
        else if len_never (arity + 1) len then
          (* Needs an [(arity + 1)]-element array; unreachable for the
             bare-string form, so skip straight to the next case. *)
          next
        else
          [%expr
            if Stdlib.( = ) [%e tag] [%e estring ~loc:n.loc n.txt] then
              [%e
                ensure_json_array_len ~loc ~allow_any_constr (arity + 1)
                  len [%expr x]
                  ~else_:
                    (if Stdlib.( = ) arity 0 then make None
                     else
                       make
                         (Some
                            (fun ~array ~len:_ ->
                              build_tuple ~loc derive 1 t.tpl_types array)))]
            else [%e next]]

  let is_allow_any_constr vcs = vcs_attr_json_allow_any vcs

  let deriving : Conv.deriving =
    deriving_of () ~name:"of_json"
      ~of_t:(fun ~loc -> [%type: Js.Json.t])
      ~is_allow_any_constr ~derive_of_tuple ~derive_of_record
      ~derive_of_labeled_tuple ~derive_of_variant ~derive_of_variant_case
end

module To_json = struct
  let as_json ~loc x = [%expr (Obj.magic [%e x] : Js.Json.t)]

  let derive_of_tuple derive t es =
    let loc = t.tpl_loc in
    as_json ~loc (pexp_array ~loc (List.map2 t.tpl_types es ~f:derive))

  let derive_of_record derive t es =
    let loc = t.rcd_loc in
    let fs =
      List.map2 t.rcd_fields es ~f:(fun ld x ->
          let k =
            let k = ld.pld_name in
            Option.value ~default:k (Attrs.Json.ld_attr_json_key ld)
          in
          let v =
            let v = derive ld.pld_type x in
            match ld_drop_default ld with
            | `No -> v
            | `Drop_option ->
                [%expr
                  match [%e x] with
                  | Stdlib.Option.None -> Js.Undefined.empty
                  | Stdlib.Option.Some _ -> Js.Undefined.return [%e v]]
            | `Drop_default (cmp, def) ->
                [%expr
                  if [%e cmp] [%e x] [%e def] then Js.Undefined.empty
                  else Js.Undefined.return [%e v]]
            | `Drop_default_if_json_equal def ->
                [%expr
                  let json = [%e v] in
                  if Melange_json.equal json [%e derive ld.pld_type def]
                  then Js.Undefined.empty
                  else Js.Undefined.return json]
          in
          map_loc lident k, v)
    in
    let record = pexp_record ~loc fs None in
    as_json ~loc [%expr [%mel.obj [%e record]]]

  let derive_of_variant_case ?(is_compact_variants = false) derive c es =
    match c with
    | Vcs_tuple (n, t) when vcs_attr_json_catch_all t.tpl_ctx -> (
        let loc = n.loc in
        match t.tpl_types, es with
        | [ _ ], [ arg_e ] ->
            [%expr
              match [%e arg_e].payload with
              | Stdlib.Option.None ->
                  (Obj.magic ([%e arg_e].tag : string) : Js.Json.t)
              | Stdlib.Option.Some xs ->
                  let head =
                    (Obj.magic ([%e arg_e].tag : string) : Js.Json.t)
                  in
                  let rest =
                    Stdlib.List.map
                      (fun (j : Melange_json.t) ->
                        (Obj.magic j : Js.Json.t))
                      xs
                  in
                  (Obj.magic
                     (Stdlib.Array.of_list (head :: rest)
                       : Js.Json.t array)
                    : Js.Json.t)]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] requires exactly one argument: a record \
               type with fields `tag : string` and `payload : \
               Melange_json.t list option` (typically \
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
              | Stdlib.Option.None ->
                  (Obj.magic ([%e tag_e] : string) : Js.Json.t)
              | Stdlib.Option.Some xs ->
                  let head =
                    (Obj.magic ([%e tag_e] : string) : Js.Json.t)
                  in
                  let rest =
                    Stdlib.List.map
                      (fun (j : Melange_json.t) ->
                        (Obj.magic j : Js.Json.t))
                      xs
                  in
                  (Obj.magic
                     (Stdlib.Array.of_list (head :: rest)
                       : Js.Json.t array)
                    : Js.Json.t)]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] inline record must have exactly two \
               fields named `tag` and `payload` (in that order), with \
               types `string` and `Melange_json.t list option`")
    | Vcs_record (n, r) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name r.rcd_ctx) in
        let tag =
          [%expr (Obj.magic [%e estring ~loc:n.loc n.txt] : Js.Json.t)]
        in
        let es = [ derive_of_record derive r es ] in
        as_json ~loc (pexp_array ~loc (tag :: es))
    | Vcs_tuple (_n, t) when vcs_attr_json_allow_any t.tpl_ctx -> (
        match es with
        | [ x ] -> x
        | es ->
            failwith
              (sprintf "expected a tuple of length 1, got %i"
                 (List.length es)))
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        let arity = List.length t.tpl_types in
        if is_compact_variants && arity = 0 then
          as_json ~loc (estring ~loc:n.loc n.txt)
        else
          let tag =
            [%expr (Obj.magic [%e estring ~loc:n.loc n.txt] : Js.Json.t)]
          in
          let es = List.map2 t.tpl_types es ~f:derive in
          as_json ~loc (pexp_array ~loc (tag :: es))

  let deriving : Conv.deriving =
    deriving_to () ~name:"to_json"
      ~t_to:(fun ~loc -> [%type: Js.Json.t])
      ~derive_of_tuple ~derive_of_labeled_tuple:derive_of_record
      ~derive_of_record ~derive_of_variant_case
end

let () =
  let of_json = Conv.register Of_json.deriving in
  let to_json = Conv.register To_json.deriving in
  let json =
    Conv.register_combined "json" [ To_json.deriving; Of_json.deriving ]
  in
  let (_ : Deriving.t) = Of_json_string.register ~of_json () in
  let (_ : Deriving.t) = To_json_string.register ~to_json () in
  let (_ : Deriving.t) = Json_string.register ~json () in
  let (_ : Deriving.t) = Ppx_deriving_jsonschema.register () in
  Linter.register ()
