open Ppxlib

let lint_errorf ~loc fmt =
  Printf.ksprintf (fun msg -> Driver.Lint_error.of_string loc msg) fmt

let json_derivers =
  [
    "json";
    "of_json";
    "to_json";
    "json_string";
    "of_json_string";
    "to_json_string";
  ]

let rec deriver_names e =
  match e.pexp_desc with
  | Pexp_ident { txt = Lident name; _ } -> [ name ]
  | Pexp_apply (fn, _) -> deriver_names fn
  | Pexp_tuple es -> List.concat_map deriver_names es
  | _ -> []

let derivers_of_td (td : type_declaration) =
  List.concat_map
    (fun attr ->
      match attr.attr_name.txt, attr.attr_payload with
      | "deriving", PStr [ { pstr_desc = Pstr_eval (e, _); _ } ] ->
          deriver_names e
      | _ -> [])
    td.ptype_attributes

let derivers_of_group (tds : type_declaration list) =
  List.concat_map derivers_of_td tds

let group_derives_json tds =
  List.exists (fun d -> List.mem d json_derivers) (derivers_of_group tds)

let group_derives_jsonschema tds =
  List.mem "jsonschema" (derivers_of_group tds)

module No_qualified_shared_attrs = struct
  let shared_td_attrs =
    [ "allow_extra_fields"; "disallow_extra_fields"; "compact_variants" ]

  let shared_ld_attrs = [ "key"; "option"; "default" ]

  let shared_cd_attrs =
    [ "name"; "allow_extra_fields"; "disallow_extra_fields" ]

  let shared_rtag_attrs = [ "name" ]

  let check_deriving_both_json_jsonschema (tds : type_declaration list) =
    group_derives_json tds && group_derives_jsonschema tds

  let check_attrs ~shared acc (attrs : attributes) =
    List.fold_left
      (fun acc (attr : attribute) ->
        let name = attr.attr_name.txt in
        match String.index_opt name '.' with
        | None -> acc
        | Some i ->
            let prefix = String.sub name 0 i in
            let base =
              String.sub name (i + 1) (String.length name - i - 1)
            in
            if
              (prefix = "json" || prefix = "jsonschema")
              && List.mem base shared
            then
              lint_errorf ~loc:attr.attr_loc
                "melange-json linter: [@%s] only applies to the %s \
                 deriver, but this type derives both json and \
                 jsonschema; use the unqualified [@%s] so it applies to \
                 both"
                name prefix base
              :: acc
            else acc)
      acc attrs

  let rule =
    object (self)
      inherit [Driver.Lint_error.t list] Ast_traverse.fold as super
      val mutable deriving_both_json_n_jsonschema = false

      method private flag_deriving_type tds =
        deriving_both_json_n_jsonschema <-
          check_deriving_both_json_jsonschema tds

      method private unflag_deriving_type =
        deriving_both_json_n_jsonschema <- false

      method! structure_item item acc =
        match item.pstr_desc with
        | Pstr_type (_, tds) ->
            self#flag_deriving_type tds;
            let acc = super#structure_item item acc in
            self#unflag_deriving_type;
            acc
        | _ -> super#structure_item item acc

      method! signature_item item acc =
        match item.psig_desc with
        | Psig_type (_, tds) ->
            self#flag_deriving_type tds;
            let acc = super#signature_item item acc in
            self#unflag_deriving_type;
            acc
        | _ -> super#signature_item item acc

      method! type_declaration td acc =
        let acc = super#type_declaration td acc in
        if deriving_both_json_n_jsonschema then
          check_attrs ~shared:shared_td_attrs acc td.ptype_attributes
        else acc

      method! label_declaration ld acc =
        let acc = super#label_declaration ld acc in
        if deriving_both_json_n_jsonschema then
          check_attrs ~shared:shared_ld_attrs acc ld.pld_attributes
        else acc

      method! constructor_declaration cd acc =
        let acc = super#constructor_declaration cd acc in
        if deriving_both_json_n_jsonschema then
          check_attrs ~shared:shared_cd_attrs acc cd.pcd_attributes
        else acc

      method! row_field rf acc =
        let acc = super#row_field rf acc in
        if deriving_both_json_n_jsonschema then
          check_attrs ~shared:shared_rtag_attrs acc rf.prf_attributes
        else acc
    end
end

let rules : Driver.Lint_error.t list Ast_traverse.fold list =
  [ No_qualified_shared_attrs.rule ]

let lint_impl (structure : structure) : Driver.Lint_error.t list =
  List.rev
    (List.fold_left
       (fun acc rule -> rule#structure structure acc)
       [] rules)

let lint_intf (signature : signature) : Driver.Lint_error.t list =
  List.rev
    (List.fold_left
       (fun acc rule -> rule#signature signature acc)
       [] rules)

let register () =
  Driver.register_transformation "melange_json_linter" ~lint_impl
    ~lint_intf
