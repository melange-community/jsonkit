open Printf
open StdLabels
open Ppxlib
open Ast_builder.Default
open Ast_helpers
open Conv
open Conv.Variant
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

  let build_record ~loc ~json derive (record : Record.t) make =
    let fields = record.fields in
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
    if record.allow_extra_fields then body
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
        if Stdlib.( = ) [%e len] 0 then Stdlib.Option.None
        else if Stdlib.( = ) [%e len] 1 then Stdlib.Option.Some []
        else
          let rest =
            Stdlib.Array.sub [%e array] 1 (Stdlib.( - ) [%e len] 1)
            |> Stdlib.Array.to_list
            |> Stdlib.List.map (fun j -> Obj.magic j)
          in
          Stdlib.Option.Some rest
      in
      ({ tag = [%e tag]; payload } : Jsonkit.unknown_variant_case)]

  let derive_of_variant_case ?(is_compact_variants = false) ~tag ~array
      ~len ~allow_any_constr derive case next =
    (* The payload expression can only be built once [array] / [len] are in
       scope, so cases hand it over as a function of the two. *)
    let construct payload =
      case_construct case (Option.map (fun f -> f ~array ~len) payload)
    in
    match case with
    | Vcs_tuple { name; attr = { catch_all = true; _ }; _ }
    | Vcs_record { name; attr = { catch_all = true; _ }; _ } ->
        construct
          (Some (build_unknown_variant_case_record ~loc:name.loc ~tag))
    | Vcs_record _ when len_never 2 len ->
        (* Record variants need [["Name", {...}]] (length 2); unreachable for
           the bare-string form, so skip straight to the next case. *)
        next
    | Vcs_record { name; tag = expected_tag; record; _ } ->
        let loc = name.loc in
        let build ~loc fs =
          let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
          construct
            (Some (fun ~array:_ ~len:_ -> pexp_record ~loc fs None))
        in
        [%expr
          if
            Stdlib.( = ) [%e tag]
              [%e estring ~loc:expected_tag.loc expected_tag.txt]
          then
            [%e
              ensure_json_array_len ~loc ~allow_any_constr 2 len [%expr x]
                ~else_:
                  [%expr
                    let fs = Js.Array.unsafe_get [%e array] 1 in
                    [%e ensure_json_object ~loc [%expr fs]];
                    [%e
                      build_record ~loc derive record ~json:[%expr fs]
                        build]]]
          else [%e next]]
    | Vcs_tuple { name; tag = expected_tag; types; _ } ->
        let loc = name.loc in
        let is_expected_tag =
          [%expr
            Stdlib.( = ) [%e tag]
              [%e estring ~loc:expected_tag.loc expected_tag.txt]]
        in
        let arity = List.length types in
        if is_compact_variants && arity = 0 then
          [%expr
            if [%e is_expected_tag] then [%e construct None]
            else [%e next]]
        else if len_never (arity + 1) len then
          (* Needs an [(arity + 1)]-element array; unreachable for the
             bare-string form, so skip straight to the next case. *)
          next
        else
          [%expr
            if [%e is_expected_tag] then
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
     [Conv.deriving_fn] traversal. *)
  let deriving_fn : Conv.deriving_fn =
    (object (self)
       inherit deriving_fn
       method name = "of_json"
       method t ~loc _name t = [%type: Jsonkit.Json.t -> [%t t]]

       (* One link of the tag-dispatch chain: "if this case matches, decode
          it; otherwise fall through to [next]". Shared by the variant fold
          and the polyvariant [`Rtag] fold. *)
       method private variant_case_link ~compact ~allow_any_constr ~case
           next :
           array:expression ->
           len:expression ->
           tag:expression ->
           expression =
         fun ~array ~len ~tag ->
           derive_of_variant_case ~is_compact_variants:compact ~tag ~array
             ~len self#derive_of_core_type case ~allow_any_constr
             (next ~array ~len ~tag)

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
         let build ~loc fs =
           let fs =
             List.map fs ~f:(fun (n, v) -> labeled_tuple_arg_label n, v)
           in
           pexp_labeled_tuple ~loc fs
         in
         [%expr
           [%e ensure_json_object ~loc x];
           [%e
             build_record ~loc self#derive_of_core_type
               (Record.of_labeled_tuple ts)
               ~json:x build]]

       method! derive_of_record td fs x =
         let loc = td.ptype_loc in
         let build ~loc fs =
           let fs = List.map fs ~f:(fun (n, v) -> map_loc lident n, v) in
           pexp_record ~loc fs None
         in
         [%expr
           [%e ensure_json_object ~loc x];
           [%e
             build_record ~loc self#derive_of_core_type
               (Record.of_type_declaration td fs)
               ~json:x build]]

       method! derive_of_variant td cs x =
         let loc = td.ptype_loc in
         let { compact; cases; allow_any = allow_any_constr } =
           resolve_variant td cs
         in
         (* The if-else chain is built by folding from the last case, so the
            cases are walked in reverse — including when listing the shapes
            the decoder expects. *)
         let cases = List.rev (without_allow_any cases) in
         let body =
           List.fold_left cases
             ~init:
               (match allow_any_constr with
               | Some allow_any_constr ->
                   fun ~array:_ ~len:_ ~tag:_ -> allow_any_constr x
               | None ->
                   let error_message =
                     expected_message
                       (List.map cases ~f:(case_json_shape ~compact))
                   in
                   fun ~array:_ ~len:_ ~tag:_ ->
                     [%expr
                       Jsonkit.of_json_error ~json:[%e x]
                         [%e estring ~loc error_message]])
             ~f:(fun next case ->
               self#variant_case_link ~compact ~allow_any_constr ~case
                 next)
         in
         dispatch_on_tag ~loc ~is_compact_variants:compact
           ~allow_any_constr body x

       method! derive_of_polyvariant ?td t (cs : row_field list) x =
         let loc = t.ptyp_loc in
         let { compact; pvcs; allow_any = allow_any_constr } =
           resolve_polyvariant ?td cs
         in
         let cs, pvcs = without_allow_any_rows cs pvcs in
         let tags, inherits =
           List.partition_map pvcs ~f:(function
             | Pvc_tag case -> Left case
             | Pvc_inherit (n, ts) -> Right (n, ts))
         in
         let catch_alls, tags =
           List.partition tags ~f:(fun (case : tuple_case) ->
               case.attr.catch_all)
         in
         let fallback =
           match allow_any_constr with
           | Some allow_any_constr ->
               fun ~array:_ ~len:_ ~tag:_ -> allow_any_constr x
           | None ->
               let error_message =
                 expected_message
                   (polyvariant_json_shapes ~compact ~loc pvcs)
               in
               fun ~array:_ ~len:_ ~tag:_ ->
                 [%expr
                   Jsonkit.of_json_unexpected_variant ~json:x
                     [%e estring ~loc error_message]]
         in
         let link cases next =
           List.fold_right cases ~init:next ~f:(fun case next ->
               self#variant_case_link ~compact ~allow_any_constr
                 ~case:(Vcs_tuple case) next)
         in
         let inherit_ (n, ts) next =
           let maybe_e = self#derive_type_ref ~loc self#name n ts x in
           let t = ptyp_variant ~loc cs Closed None in
           fun ~array ~len ~tag ->
             [%expr
               match [%e maybe_e] with
               | e -> (e :> [%t t])
               | exception
                   Jsonkit.Of_json_error (Jsonkit.Unexpected_variant _) ->
                   [%e next ~array ~len ~tag]]
         in
         let body =
           link tags
             (List.fold_right inherits ~f:inherit_
                ~init:(link catch_alls fallback))
         in
         dispatch_on_tag ~loc ~is_compact_variants:compact
           ~allow_any_constr body x
     end
      :> Conv.deriving_fn)

  let deriving = (deriving_fn :> Conv.deriving)
end

module Json_reader = struct
  let is_plain_json_literal text =
    String.for_all text ~f:(fun c ->
        Char.code c >= 0x20
        && Char.code c <= 0x7e
        && c <> '"'
        && c <> '\\')

  let object_prototype_properties =
    [
      "__proto__";
      "__defineGetter__";
      "__defineSetter__";
      "__lookupGetter__";
      "__lookupSetter__";
      "constructor";
      "hasOwnProperty";
      "isPrototypeOf";
      "propertyIsEnumerable";
      "toLocaleString";
      "toString";
      "valueOf";
    ]

  let reads_record_directly (record : Record.t) =
    List.for_all record.fields ~f:(fun (f : Record.field) ->
        is_plain_json_literal f.key.txt
        && not (List.mem f.key.txt ~set:object_prototype_properties))

  let reads_case_directly = function
    | Vcs_tuple { attr; tag; _ } ->
        (not attr.allow_any)
        && (not attr.catch_all)
        && is_plain_json_literal tag.txt
    | Vcs_record { attr; tag; record; _ } ->
        (not attr.allow_any)
        && (not attr.catch_all)
        && is_plain_json_literal tag.txt
        && reads_record_directly record

  let mentions_type_variable =
    object
      inherit [bool] Ast_traverse.fold as super

      method! core_type t found =
        match t.ptyp_desc with
        | Ptyp_var _ -> true
        | _ -> super#core_type t found
    end

  let through_of_json ~loc ~polymorphic of_json r =
    if polymorphic then
      not_supported ~loc
        "type parameters on a type that json_reader decodes through \
         of_json";
    [%expr
      Jsonkit_reader.of_json (fun x -> [%e of_json [%expr x]]) [%e r]]

  let has_type_parameters (td : type_declaration) =
    match td.ptype_params with [] -> false | _ :: _ -> true

  let lit ~loc r literal =
    [%expr Jsonkit_reader.lit [%e r] [%e estring ~loc literal]]

  let cell_name (f : Record.field) = "json_reader_field_" ^ f.name.txt
  let cell ~loc f = evar ~loc (cell_name f)

  let build_record ~loc derive (record : Record.t) make r =
    let fields = record.fields in
    let read (f : Record.field) =
      [%expr Stdlib.( := ) [%e cell ~loc f] [%e derive f.type_ r]]
    in
    let rec in_declared_order = function
      | [] -> lit ~loc r "}"
      | (f : Record.field) :: rest -> (
          let key = lit ~loc r (sprintf {|,"%s":|} f.key.txt) in
          let rest = in_declared_order rest in
          match f.default with
          | None ->
              [%expr
                Stdlib.( && ) [%e key]
                  ([%e read f];
                   [%e rest])]
          | Some _ ->
              [%expr
                if [%e key] then [%e read f];
                [%e rest]])
    in
    let in_declared_order =
      match fields with
      | [] -> lit ~loc r "{}"
      | first :: rest ->
          [%expr
            Stdlib.( && )
              [%e lit ~loc r (sprintf {|{"%s":|} first.key.txt)]
              ([%e read first];
               [%e in_declared_order rest])]
    in
    let unknown_member =
      if record.allow_extra_fields then
        [%expr Jsonkit_reader.skip_member [%e r]]
      else [%expr Jsonkit_reader.fallback ()]
    in
    let member =
      List.fold_right fields ~init:unknown_member
        ~f:(fun (f : Record.field) next ->
          let literal = sprintf {|%s":|} f.key.txt in
          [%expr
            if
              Stdlib.( && )
                (Stdlib.( = ) json_reader_key
                   [%e eint ~loc (Char.code literal.[0])])
                [%e lit ~loc r literal]
            then [%e read f]
            else [%e next]])
    in
    let in_any_order =
      [%expr
        if Jsonkit_reader.object_start [%e r] then begin
          let json_reader_more = Stdlib.ref true in
          while Stdlib.( ! ) json_reader_more do
            let json_reader_key = Jsonkit_reader.member_start [%e r] in
            [%e member];
            Stdlib.( := ) json_reader_more
              (Jsonkit_reader.more_members [%e r])
          done
        end]
    in
    let value (f : Record.field) =
      ( f.name,
        let absent =
          match f.default with
          | None -> [%expr Jsonkit_reader.fallback ()]
          | Some default -> default
        in
        [%expr
          if
            Stdlib.( == )
              (Stdlib.Obj.repr (Stdlib.( ! ) [%e cell ~loc f]))
              Jsonkit_reader.absent
          then [%e absent]
          else Stdlib.( ! ) [%e cell ~loc f]] )
    in
    let body =
      [%expr
        if
          Stdlib.not
            (Stdlib.( && )
               (Jsonkit_reader.speculating [%e r])
               [%e in_declared_order])
        then begin
          Jsonkit_reader.stop_speculating [%e r] json_reader_start;
          [%e in_any_order]
        end;
        [%e make ~loc (List.map fields ~f:value)]]
    in
    let body =
      List.fold_right fields ~init:body ~f:(fun f body ->
          [%expr
            let [%p pvar ~loc (cell_name f)] =
              Stdlib.ref (Stdlib.Obj.obj Jsonkit_reader.absent)
            in
            [%e body]])
    in
    [%expr
      let json_reader_start = Jsonkit_reader.position [%e r] in
      [%e body]]

  let read_items ~loc derive types r finish =
    let names =
      List.mapi types ~f:(fun i _ -> sprintf "json_reader_item_%i" i)
    in
    let closed =
      [%expr
        Jsonkit_reader.char [%e r] 93;
        [%e finish (List.map names ~f:(evar ~loc))]]
    in
    List.fold_right
      (List.mapi (List.combine names types) ~f:(fun i item -> i, item))
      ~init:closed
      ~f:(fun (i, (name, t)) rest ->
        let bound =
          [%expr
            let [%p pvar ~loc name] = [%e derive t r] in
            [%e rest]]
        in
        if i = 0 then bound
        else
          [%expr
            Jsonkit_reader.char [%e r] 44;
            [%e bound]])

  let read_cases ~loc ~compact derive cases r =
    List.fold_right cases ~init:[%expr Jsonkit_reader.fallback ()]
      ~f:(fun case next ->
        match case with
        | Vcs_tuple { tag; types = []; _ } ->
            let literal =
              if compact then sprintf {|"%s"|} tag.txt
              else sprintf {|["%s"]|} tag.txt
            in
            [%expr
              if [%e lit ~loc r literal] then
                [%e case_construct case None]
              else [%e next]]
        | Vcs_tuple { tag; types; _ } ->
            [%expr
              if [%e lit ~loc r (sprintf {|["%s",|} tag.txt)] then
                [%e
                  read_items ~loc derive types r (fun items ->
                      case_construct case (Some (pexp_tuple ~loc items)))]
              else [%e next]]
        | Vcs_record { tag; record; _ } ->
            let make ~loc fs =
              let fs =
                List.map fs ~f:(fun (n, v) -> map_loc lident n, v)
              in
              [%expr
                Jsonkit_reader.char [%e r] 93;
                [%e case_construct case (Some (pexp_record ~loc fs None))]]
            in
            [%expr
              if [%e lit ~loc r (sprintf {|["%s",|} tag.txt)] then
                [%e build_record ~loc derive record make r]
              else [%e next]])

  let deriving : Conv.deriving =
    (object (self)
       inherit deriving_fn as super
       method name = "json_reader"
       method t ~loc _name t = [%type: Jsonkit_reader.t -> [%t t]]

       method! private derive_type_ref' ~loc name n ts =
         match n.txt, ts with
         | ( Lident
               (("string" | "bool" | "int" | "float" | "int64" | "unit")
                as builtin),
             [] ) ->
             As_val
               (pexp_ident ~loc
                  { loc; txt = Ldot (Lident "Jsonkit_reader", builtin) })
         | Lident "option", [ t ] ->
             As_fun
               (fun r ->
                 [%expr
                   if Jsonkit_reader.null [%e r] then Stdlib.Option.None
                   else
                     Stdlib.Option.Some [%e self#derive_of_core_type t r]])
         | Lident "list", [ t ] ->
             As_fun
               (fun r ->
                 [%expr
                   if Jsonkit_reader.array_start [%e r] then
                     let[@tail_mod_cons] rec json_reader_items () =
                       let json_reader_item =
                         [%e self#derive_of_core_type t r]
                       in
                       if Jsonkit_reader.more_items [%e r] then
                         json_reader_item :: json_reader_items ()
                       else [ json_reader_item ]
                     in
                     json_reader_items ()
                   else []])
         | Lident "array", [ t ] ->
             As_fun
               (fun r ->
                 [%expr
                   let json_reader_items = [||] in
                   if Jsonkit_reader.array_start [%e r] then begin
                     let json_reader_more = Stdlib.ref true in
                     while Stdlib.( ! ) json_reader_more do
                       Jsonkit_reader.push json_reader_items
                         [%e self#derive_of_core_type t r];
                       Stdlib.( := ) json_reader_more
                         (Jsonkit_reader.more_items [%e r])
                     done
                   end;
                   json_reader_items])
         | _ -> super#derive_type_ref' ~loc name n ts

       method! derive_of_tuple t ts r =
         let loc = t.ptyp_loc in
         [%expr
           Jsonkit_reader.char [%e r] 91;
           [%e
             read_items ~loc self#derive_of_core_type ts r
               (pexp_tuple ~loc)]]

       method! derive_of_labeled_tuple t ts r =
         let loc = t.ptyp_loc in
         let record = Record.of_labeled_tuple ts in
         if reads_record_directly record then
           let make ~loc fs =
             pexp_labeled_tuple ~loc
               (List.map fs ~f:(fun (n, v) ->
                    labeled_tuple_arg_label n, v))
           in
           build_record ~loc self#derive_of_core_type record make r
         else
           through_of_json ~loc
             ~polymorphic:(mentions_type_variable#core_type t false)
             (Of_json.deriving_fn#derive_of_labeled_tuple t ts)
             r

       method! derive_of_record td fs r =
         let loc = td.ptype_loc in
         let record = Record.of_type_declaration td fs in
         if reads_record_directly record then
           let make ~loc fs =
             pexp_record ~loc
               (List.map fs ~f:(fun (n, v) -> map_loc lident n, v))
               None
           in
           build_record ~loc self#derive_of_core_type record make r
         else
           through_of_json ~loc ~polymorphic:(has_type_parameters td)
             (Of_json.deriving_fn#derive_of_record td fs)
             r

       method! derive_of_variant td cs r =
         let loc = td.ptype_loc in
         let { compact; cases; _ } = resolve_variant td cs in
         if List.for_all cases ~f:reads_case_directly then
           read_cases ~loc ~compact self#derive_of_core_type cases r
         else
           through_of_json ~loc ~polymorphic:(has_type_parameters td)
             (Of_json.deriving_fn#derive_of_variant td cs)
             r

       method! derive_of_polyvariant ?td t cs r =
         let loc = t.ptyp_loc in
         let { compact; pvcs; _ } = resolve_polyvariant ?td cs in
         let cases =
           List.filter_map pvcs ~f:(function
             | Pvc_tag case -> Some (Vcs_tuple case)
             | Pvc_inherit _ -> None)
         in
         if
           List.length cases = List.length pvcs
           && List.for_all cases ~f:reads_case_directly
         then read_cases ~loc ~compact self#derive_of_core_type cases r
         else
           through_of_json ~loc
             ~polymorphic:
               (Option.fold td ~none:false ~some:has_type_parameters
               || mentions_type_variable#core_type t false)
             (Of_json.deriving_fn#derive_of_polyvariant ?td t cs)
             r
     end
      :> Conv.deriving)
end

module To_json = struct
  let as_json ~loc x = [%expr (Obj.magic [%e x] : Js.Json.t)]
  let json_array ~loc es = as_json ~loc (pexp_array ~loc es)

  let json_string ~loc (n : label loc) =
    as_json ~loc (estring ~loc:n.loc n.txt)

  let catch_all_encode ~loc ~tag ~payload =
    [%expr
      match [%e payload] with
      | Stdlib.Option.None -> (Obj.magic ([%e tag] : string) : Js.Json.t)
      | Stdlib.Option.Some xs ->
          let head = (Obj.magic ([%e tag] : string) : Js.Json.t) in
          let rest =
            Stdlib.List.map (fun (j : Jsonkit.t) -> Obj.magic j) xs
          in
          (Obj.magic
             (Stdlib.Array.of_list (head :: rest) : Js.Json.t array)
            : Js.Json.t)]

  let derive_of_record ~loc derive fields es =
    let fs =
      List.map2 fields es ~f:(fun (f : Record.to_field) x ->
          let v =
            let v = derive f.type_ x in
            match f.drop with
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

  let deriving : Conv.deriving =
    deriving_to () ~name:"to_json"
      ~t_to:(fun ~loc -> [%type: Jsonkit.Json.t])
      ~json_array ~json_string ~catch_all_encode ~derive_of_record
end

let () =
  let of_json = Conv.register Of_json.deriving in
  let to_json = Conv.register To_json.deriving in
  let (_ : Deriving.t) = Conv.register Json_reader.deriving in
  let json =
    Conv.register_combined "json" [ To_json.deriving; Of_json.deriving ]
  in
  let (_ : Deriving.t) = Of_json_string.register ~of_json () in
  let (_ : Deriving.t) = To_json_string.register ~to_json () in
  let (_ : Deriving.t) = Json_string.register ~json () in
  let (_ : Deriving.t) = Ppx_deriving_jsonschema.register () in
  Linter.register ()
