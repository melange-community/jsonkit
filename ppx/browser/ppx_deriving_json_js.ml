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
  let build_tuple ~loc derive si (ts : core_type list) e =
    pexp_tuple ~loc
      (List.mapi ts ~f:(fun i t ->
           derive t
             [%expr Js.Array.unsafe_get [%e e] [%e eint ~loc (si + i)]]))

  let build_js_type ~loc (fs : Record.field list) =
    let f (fld : Record.field) =
      let n = fld.key in
      let pof_desc = Otag (n, [%type: Js.Json.t Js.undefined]) in
      { pof_loc = loc; pof_attributes = []; pof_desc }
    in
    let row = ptyp_object ~loc (List.map fs ~f) Closed in
    [%type: [%t row] Js.t]

  let build_record ~allow_extra_fields ~loc ~json derive
      (fields : Record.field list) make =
    let handle_field obj (f : Record.field) =
      ( f.name,
        let n = f.key in
        [%expr
          match
            Js.Undefined.toOption
              [%e obj]##[%e pexp_ident ~loc:n.loc (map_loc lident n)]
          with
          | Stdlib.Option.Some v -> [%e derive f.type_ [%expr v]]
          | Stdlib.Option.None ->
              [%e
                match f.default with
                | Some default -> default
                | None ->
                    [%expr
                      Jsonkit.of_json_error ~json:x
                        [%e
                          estring ~loc
                            (sprintf "expected field %S to be present"
                               n.txt)]]]] )
    in
    let is_known_field name =
      List.fold_left fields ~init:[%expr false]
        ~f:(fun acc (f : Record.field) ->
          let n = f.key in
          [%expr
            Stdlib.( || )
              (Stdlib.( = ) [%e name] [%e estring ~loc:n.loc n.txt])
              [%e acc]])
    in
    let body =
      [%expr
        let fs = (Obj.magic [%e json] : [%t build_js_type ~loc fields]) in
        [%e
          let decoded_fields =
            List.map fields ~f:(handle_field [%expr fs])
          in
          make ~loc decoded_fields]]
    in
    if allow_extra_fields then body
    else
      [%expr
        let keys =
          Js.Dict.keys (Obj.magic [%e json] : Js.Json.t Js.Dict.t)
        in
        let len = Js.Array.length keys in
        let rec iter i =
          if Stdlib.( < ) i len then
            let name = Js.Array.unsafe_get keys i in
            if [%e is_known_field [%expr name]] then
              iter (Stdlib.( + ) i 1)
            else
              Jsonkit.of_json_error ~json:x
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
        Jsonkit.of_json_error ~json:[%e x]
          [%e estring ~loc (sprintf "expected a JSON object")]]

  let ensure_json_array_len ~loc ~allow_any_constr ~else_ n len x =
    let error =
      match allow_any_constr with
      | Some allow_any_constr -> allow_any_constr x
      | None ->
          [%expr
            Jsonkit.of_json_error ~json:[%e x]
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

  let dispatch_on_tag ~loc ?(is_compact_variants = false)
      ~allow_any_constr body x =
    let not_array_error =
      match allow_any_constr with
      | Some allow_any_constr -> allow_any_constr x
      | None ->
          [%expr
            Jsonkit.of_json_error ~json:[%e x]
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
                    Jsonkit.of_json_error ~json:[%e x]
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
      let payload =
        if Stdlib.( = ) len 0 then Stdlib.Option.None
        else if Stdlib.( = ) len 1 then Stdlib.Option.Some []
        else
          let rest =
            Stdlib.Array.sub [%e array] 1 (Stdlib.( - ) [%e len] 1)
            |> Stdlib.Array.to_list
            |> Stdlib.List.map (fun j -> (Obj.magic j : Jsonkit.t))
          in
          Stdlib.Option.Some rest
      in
      ({ tag = [%e tag]; payload } : Jsonkit.unknown_variant_case)]

  let derive_of_variant_case ?(is_compact_variants = false) ~tag ~array
      ~len ~allow_any_constr derive construct case next =
    match case with
    | Vcs_tuple { name; types; attr = { catch_all = true; _ }; _ } -> (
        let loc = name.loc in
        match types with
        | [ _ ] ->
            construct (Some (build_unknown_variant_case_record ~loc ~tag))
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] requires exactly one argument: a record \
               type with fields `tag : string` and `payload : Jsonkit.t \
               list option` (typically [Jsonkit.unknown_variant_case])")
    | Vcs_record { loc; fields; attr = { catch_all = true; _ }; _ } -> (
        match fields with
        | [
         { name = { txt = "tag"; _ }; _ };
         { name = { txt = "payload"; _ }; _ };
        ] ->
            construct (Some (build_unknown_variant_case_record ~loc ~tag))
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] inline record must have exactly two \
               fields named `tag` and `payload` (in that order), with \
               types `string` and `Jsonkit.t list option`")
    | Vcs_record _ when len_never 2 len ->
        (* Record variants need [["Name", {...}]] (length 2); unreachable for
           the bare-string form, so skip straight to the next case. *)
        next
    | Vcs_record { name; fields; attr; allow_extra_fields; _ } ->
        let loc = name.loc in
        let n = Option.value ~default:name attr.json_name in
        let build ~loc fs =
          let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
          construct
            (Some (fun ~array:_ ~len:_ -> pexp_record ~loc fs None))
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
                      build_record ~allow_extra_fields ~loc derive fields
                        ~json:[%expr fs] build]]]
          else [%e next]]
    | Vcs_tuple { name; types; attr; _ } ->
        let loc = name.loc in
        let n = Option.value ~default:name attr.json_name in
        let arity = List.length types in
        if is_compact_variants && arity = 0 then
          [%expr
            if Stdlib.( = ) [%e tag] [%e estring ~loc:n.loc n.txt] then
              [%e construct None]
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
                    (if Stdlib.( = ) arity 0 then construct None
                     else
                       construct
                         (Some
                            (fun ~array ~len:_ ->
                              build_tuple ~loc derive 1 types array)))]
            else [%e next]]

  (* of_json for the browser: JSON is an opaque [Js.Json.t], so the variant
     decoder is a nested if-else chain (see [derive_of_variant]) rather than a
     [match]. This object plugs the module-local leaf builders into the shared
     [Conv.deriving1] traversal. *)
  let deriving : Conv.deriving =
    (object (self)
       inherit deriving1
       method name = "of_json"
       method t ~loc _name t = [%type: Js.Json.t -> [%t t]]

       (* One link of the tag-dispatch chain: "if this case matches, decode
          it; otherwise fall through to [next]". Shared by the variant fold
          and the polyvariant [`Rtag] fold. *)
       method private variant_case_link ~compact ~allow_any_constr
           ~construct ~case next :
           array:expression ->
           len:expression ->
           tag:expression ->
           expression =
         fun ~array ~len ~tag ->
           derive_of_variant_case ~is_compact_variants:compact ~tag ~array
             ~len self#derive_of_core_type (construct ~array ~len) case
             ~allow_any_constr (next ~array ~len ~tag)

       method! derive_of_tuple t ts x =
         let loc = t.ptyp_loc in
         let n = List.length ts in
         [%expr
           if
             Stdlib.( && )
               (Js.Array.isArray [%e x])
               (Stdlib.( = )
                  (Js.Array.length (Obj.magic [%e x] : Js.Json.t array))
                  [%e eint ~loc n])
           then
             let es = (Obj.magic [%e x] : Js.Json.t array) in
             [%e
               build_tuple ~loc self#derive_of_core_type 0 ts [%expr es]]
           else
             Jsonkit.of_json_error ~json:[%e x]
               [%e
                 estring ~loc
                   (sprintf "expected a JSON array of length %i" n)]]

       method! derive_of_labeled_tuple t ts x =
         let loc = t.ptyp_loc in
         let fields = Record.fields_of_labeled_tuple ts in
         let build ~loc fs =
           let fs =
             List.map fs ~f:(fun (n, v) -> labeled_tuple_arg_label n, v)
           in
           pexp_labeled_tuple ~loc fs
         in
         [%expr
           [%e ensure_json_object ~loc x];
           [%e
             build_record ~allow_extra_fields:true ~loc
               self#derive_of_core_type fields ~json:x build]]

       method! derive_of_record td fs x =
         let loc = td.ptype_loc in
         let allow_extra_fields = Attrs.Json.td_allow_extra_fields td in
         let build ~loc fs =
           let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
           pexp_record ~loc fs None
         in
         [%expr
           [%e ensure_json_object ~loc x];
           [%e
             build_record ~allow_extra_fields ~loc
               self#derive_of_core_type
               (Record.resolve_fields fs)
               ~json:x build]]

       method! derive_of_variant td cs x =
         let loc = td.ptype_loc in
         let cs = repr_variant_cases cs in
         let allow_any_constr =
           cs
           |> List.find_opt ~f:(fun cs ->
               vcs_attr_json_allow_any (`Variant_ctx cs))
           |> Option.map (fun cs e -> econstruct cs (Some e))
         in
         let cs =
           List.filter
             ~f:(fun cs ->
               not (vcs_attr_json_allow_any (`Variant_ctx cs)))
             cs
         in
         let compact = Attrs.Json.is_compact_variants td in
         let body =
           List.fold_left cs
             ~init:
               (match allow_any_constr with
               | Some allow_any_constr ->
                   fun ~array:_ ~len:_ ~tag:_ -> allow_any_constr x
               | None ->
                   let error_message =
                     Printf.sprintf "expected %s"
                       (get_constructor_names ~compact cs
                       |> String.concat ~sep:" or ")
                   in
                   fun ~array:_ ~len:_ ~tag:_ ->
                     [%expr
                       Jsonkit.of_json_error ~json:[%e x]
                         [%e estring ~loc error_message]])
             ~f:(fun next c ->
               let name = c.pcd_name in
               let construct ~array ~len payload =
                 let arg = Option.map (fun f -> f ~array ~len) payload in
                 pexp_construct (map_loc lident name) ~loc:name.loc arg
               in
               let attr = resolve_attr (`Variant_ctx c) in
               let case =
                 match c.pcd_args with
                 | Pcstr_record fields ->
                     let allow_extra_fields =
                       Attrs.Json.cd_allow_extra_fields c
                     in
                     Vcs_record
                       {
                         name;
                         loc;
                         fields = Record.resolve_fields fields;
                         attr;
                         allow_extra_fields;
                       }
                 | Pcstr_tuple types ->
                     Vcs_tuple { name; loc; types; attr }
               in
               self#variant_case_link ~compact ~allow_any_constr
                 ~construct ~case next)
         in
         dispatch_on_tag ~loc ~is_compact_variants:compact
           ~allow_any_constr body x

       method! derive_of_polyvariant ?td t (cs : row_field list) x =
         let loc = t.ptyp_loc in
         let compact =
           Option.fold ~none:false ~some:Attrs.Json.is_compact_variants td
         in
         let allow_any_constr =
           cs
           |> List.find_opt ~f:(fun cs ->
               vcs_attr_json_allow_any (`Polyvariant_ctx cs))
           |> Option.map (fun cs ->
               match cs.prf_desc with
               | Rinherit _ ->
                   failwith "[@allow_any] placed on inherit clause"
               | Rtag (n, _, _) ->
                   fun e -> pexp_variant ~loc:n.loc n.txt (Some e))
         in
         let cs =
           List.filter
             ~f:(fun cs ->
               not (vcs_attr_json_allow_any (`Polyvariant_ctx cs)))
             cs
         in
         let cases = repr_polyvariant_cases cs in
         let body =
           List.fold_left cases
             ~init:
               (match allow_any_constr with
               | Some allow_any_constr ->
                   fun ~array:_ ~len:_ ~tag:_ -> allow_any_constr x
               | None ->
                   let error_message =
                     Printf.sprintf "expected %s"
                       (cs
                       |> List.concat_map
                            ~f:(get_variant_names ~compact ~loc)
                       |> String.concat ~sep:" or ")
                   in
                   fun ~array:_ ~len:_ ~tag:_ ->
                     [%expr
                       Jsonkit.of_json_unexpected_variant ~json:x
                         [%e estring ~loc error_message]])
             ~f:(fun next (c, r) ->
               match r with
               | `Rtag (n, ts) ->
                   let construct ~array ~len payload =
                     let arg =
                       Option.map (fun f -> f ~array ~len) payload
                     in
                     pexp_variant ~loc:n.loc n.txt arg
                   in
                   let attr = resolve_attr (`Polyvariant_ctx c) in
                   let case =
                     Vcs_tuple { name = n; loc; types = ts; attr }
                   in
                   self#variant_case_link ~compact ~allow_any_constr
                     ~construct ~case next
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
                   next)
         in
         dispatch_on_tag ~loc ~is_compact_variants:compact
           ~allow_any_constr body x
     end
      :> Conv.deriving)
end

module To_json = struct
  let as_json ~loc x = [%expr (Obj.magic [%e x] : Js.Json.t)]

  let derive_of_tuple ~loc derive types es =
    as_json ~loc (pexp_array ~loc (List.map2 types es ~f:derive))

  let derive_of_record ~loc derive fields es =
    let fs =
      List.map2 fields es ~f:(fun (f : Record.field) x ->
          let v =
            let v = derive f.type_ x in
            match ld_drop_default f.ld with
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
                  if Jsonkit.equal json [%e derive f.type_ def] then
                    Js.Undefined.empty
                  else Js.Undefined.return json]
          in
          map_loc lident f.key, v)
    in
    let record = pexp_record ~loc fs None in
    as_json ~loc [%expr [%mel.obj [%e record]]]

  let derive_of_variant_case ?(is_compact_variants = false) derive c es =
    match c with
    | Vcs_tuple { name; types; attr = { catch_all = true; _ }; _ } -> (
        let loc = name.loc in
        match types, es with
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
                      (fun (j : Jsonkit.t) -> (Obj.magic j : Js.Json.t))
                      xs
                  in
                  (Obj.magic
                     (Stdlib.Array.of_list (head :: rest)
                       : Js.Json.t array)
                    : Js.Json.t)]
        | _ ->
            Location.raise_errorf ~loc
              "[@json.catch_all] requires exactly one argument: a record \
               type with fields `tag : string` and `payload : Jsonkit.t \
               list option` (typically [Jsonkit.unknown_variant_case])")
    | Vcs_record { loc; fields; attr = { catch_all = true; _ }; _ } -> (
        match fields, es with
        | ( [
              { name = { txt = "tag"; _ }; _ };
              { name = { txt = "payload"; _ }; _ };
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
                      (fun (j : Jsonkit.t) -> (Obj.magic j : Js.Json.t))
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
               types `string` and `Jsonkit.t list option`")
    | Vcs_record { name; loc; fields; attr; _ } ->
        let n = Option.value ~default:name attr.json_name in
        let tag =
          [%expr (Obj.magic [%e estring ~loc:n.loc n.txt] : Js.Json.t)]
        in
        let es = [ derive_of_record ~loc derive fields es ] in
        as_json ~loc:name.loc (pexp_array ~loc:name.loc (tag :: es))
    | Vcs_tuple { attr = { allow_any = true; _ }; _ } -> (
        match es with
        | [ x ] -> x
        | es ->
            failwith
              (sprintf "expected a tuple of length 1, got %i"
                 (List.length es)))
    | Vcs_tuple { name; types; attr; _ } ->
        let loc = name.loc in
        let n = Option.value ~default:name attr.json_name in
        let arity = List.length types in
        if is_compact_variants && arity = 0 then
          as_json ~loc (estring ~loc:n.loc n.txt)
        else
          let tag =
            [%expr (Obj.magic [%e estring ~loc:n.loc n.txt] : Js.Json.t)]
          in
          let es = List.map2 types es ~f:derive in
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
