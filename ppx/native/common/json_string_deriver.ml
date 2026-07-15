open StdLabels
open Ppxlib
open Ast_builder.Default

(* Derive a [*_json_string] value from an existing [*_json] value by mangling
   the type name through both affixes and wrapping the resulting function.
   [what] names the value being defined, [through] names the value it delegates
   to, and [make] builds the wrapper body around the delegated function. *)
let expand_via ~what ~through make ~ctxt (rec_flag, tds) =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  let expand_one (td : type_declaration) =
    let loc = td.ptype_loc in
    let pat =
      let { txt; loc } = td.ptype_name in
      let txt = Expansion_helpers.mangle what txt in
      ppat_var ~loc { Location.txt; loc }
    in
    let name_of_td_param idx (ty, _) =
      match ty.ptyp_desc with
      | Ptyp_any -> Printf.sprintf "_%d" idx
      | Ptyp_var name -> name
      | _ ->
          Location.raise_errorf ~loc:ty.ptyp_loc
            "unsupported type parameter"
    in
    let names = List.mapi td.ptype_params ~f:name_of_td_param in
    let expr =
      let of_json =
        let { txt; loc = _ } = td.ptype_name in
        let txt = Expansion_helpers.mangle through txt in
        let of_json = pexp_ident ~loc { loc; txt = lident txt } in
        pexp_apply ~loc of_json
          (List.map names ~f:(fun name -> Nolabel, evar ~loc name))
      in
      let body = make ~loc of_json in
      List.fold_left (List.rev names) ~init:body ~f:(fun e name ->
          [%expr fun [%p pvar ~loc name] -> [%e e]])
    in
    value_binding ~loc ~pat ~expr
  in
  pstr_value_list ~loc rec_flag (List.map tds ~f:expand_one)

module Of_json_string = struct
  let expand =
    expand_via ~what:(Expansion_helpers.Suffix "of_json_string")
      ~through:(Expansion_helpers.Suffix "of_json") (fun ~loc of_json ->
        [%expr fun _json -> [%e of_json] (Jsonkit.of_string _json)])

  let register ~of_json () =
    Deriving.add "of_json_string"
      ~str_type_decl:
        (Deriving.Generator.V2.make ~deps:[ of_json ] Deriving.Args.empty
           expand)
end

module To_json_string = struct
  let expand =
    expand_via ~what:(Expansion_helpers.Suffix "to_json_string")
      ~through:(Expansion_helpers.Suffix "to_json") (fun ~loc to_json ->
        [%expr fun _data -> Jsonkit.to_string ([%e to_json] _data)])

  let register ~to_json () =
    Deriving.add "to_json_string"
      ~str_type_decl:
        (Deriving.Generator.V2.make ~deps:[ to_json ] Deriving.Args.empty
           expand)
end

module Json_string = struct
  let expand ~ctxt tds =
    Of_json_string.expand ~ctxt tds @ To_json_string.expand ~ctxt tds

  let register ~json () =
    Deriving.add "json_string"
      ~str_type_decl:
        (Deriving.Generator.V2.make ~deps:[ json ] Deriving.Args.empty
           expand)
end
