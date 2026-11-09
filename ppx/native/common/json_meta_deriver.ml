open StdLabels
open Ppxlib
open Ast_builder.Default

let value_suffix = "json_keys"

let value_name (td : type_declaration) =
  let { txt; loc } = td.ptype_name in
  {
    Location.txt =
      Expansion_helpers.mangle (Expansion_helpers.Suffix value_suffix) txt;
    loc;
  }

let json_keys (td : type_declaration) =
  match td.ptype_kind with
  | Ptype_record lds ->
      let record = Conv.Record.of_type_declaration td lds in
      List.map record.fields ~f:(fun (field : Conv.Record.field) ->
          field.key)
  | _ ->
      Location.raise_errorf ~loc:td.ptype_loc
        "[@@@@deriving json_meta] expects a record type"

let expand ~ctxt (_rec_flag, tds) =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  let binding td =
    let loc = td.ptype_loc in
    let keys =
      elist ~loc
        (List.map (json_keys td) ~f:(fun (key : label loc) ->
             estring ~loc:key.loc key.txt))
    in
    value_binding ~loc
      ~pat:(ppat_var ~loc (value_name td))
      ~expr:[%expr ([%e keys] : string list)]
  in
  pstr_value_list ~loc Nonrecursive (List.map tds ~f:binding)

let expand_sig ~ctxt (_rec_flag, tds) =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  List.map tds ~f:(fun td ->
      let (_ : label loc list) = json_keys td in
      psig_value ~loc
        (value_description ~loc ~prim:[] ~name:(value_name td)
           ~type_:[%type: string list]))

let register () =
  Deriving.add "json_meta"
    ~str_type_decl:(Deriving.Generator.V2.make Deriving.Args.empty expand)
    ~sig_type_decl:
      (Deriving.Generator.V2.make Deriving.Args.empty expand_sig)
