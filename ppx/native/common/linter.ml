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

module No_misplaced_attrs = struct
  type ctx = Td | Ld | Cd | Rtag | Ct

  let shared_attributes = function
    | "key" | "option" | "default" -> Some [ Ld ]
    | "name" -> Some [ Cd; Rtag ]
    | "allow_extra_fields" | "disallow_extra_fields" -> Some [ Td; Cd ]
    | "compact_variants" -> Some [ Td ]
    | _ -> None

  let json_attributes = function
    | "allow_any" | "catch_all" -> Some [ Cd; Rtag ]
    | "drop_default" | "drop_default_if_json_equal" -> Some [ Ld ]
    | name -> shared_attributes name

  let jsonschema_attributes = function
    | "ref" -> Some [ Ld ]
    | "description" -> Some [ Td; Ld; Cd; Rtag; Ct ]
    | "format" | "minimum" | "maximum" | "attrs" -> Some [ Td; Ld; Ct ]
    | name -> shared_attributes name

  let allowed_contexts ~json ~jsonschema name =
    let contexts_of requested contexts name =
      if requested then contexts name else None
    in
    match String.index_opt name '.' with
    | Some i -> (
        let base = String.sub name (i + 1) (String.length name - i - 1) in
        match String.sub name 0 i with
        | "json" -> contexts_of json json_attributes base
        | "jsonschema" ->
            contexts_of jsonschema jsonschema_attributes base
        | _ -> None)
    | None -> (
        match
          ( contexts_of json json_attributes name,
            contexts_of jsonschema jsonschema_attributes name )
        with
        | Some a, Some b -> Some (a @ b)
        | (Some _ as x), None | None, (Some _ as x) -> x
        | None, None -> None)

  let current_ctx = function
    | Td -> "a type declaration"
    | Ld -> "a record field"
    | Cd -> "a variant constructor"
    | Rtag -> "a polymorphic variant tag"
    | Ct -> "a type expression"

  let allowed_ctx = function
    | Td -> "type declarations"
    | Ld -> "record fields"
    | Cd -> "variant constructors"
    | Rtag -> "polymorphic variant tags"
    | Ct -> "type expressions"

  let check_attrs ~json ~jsonschema ~ctx acc (attrs : attributes) =
    if not (json || jsonschema) then acc
    else
      List.fold_left
        (fun acc (attr : attribute) ->
          let name = attr.attr_name.txt in
          match allowed_contexts ~json ~jsonschema name with
          | Some allowed when not (List.mem ctx allowed) ->
              lint_errorf ~loc:attr.attr_loc
                "melange-json linter: [@%s] is not allowed on %s; it \
                 applies to %s"
                name (current_ctx ctx)
                (String.concat ", "
                   (List.map allowed_ctx (List.sort_uniq compare allowed)))
              :: acc
          | _ -> acc)
        acc attrs

  let rule =
    object (self)
      inherit [Driver.Lint_error.t list] Ast_traverse.fold as super
      val mutable derives_json = false
      val mutable derives_jsonschema = false

      method private flag_derivers tds =
        derives_json <- group_derives_json tds;
        derives_jsonschema <- group_derives_jsonschema tds

      method private unflag_derivers =
        derives_json <- false;
        derives_jsonschema <- false

      method! structure_item item acc =
        match item.pstr_desc with
        | Pstr_type (_, tds) ->
            self#flag_derivers tds;
            let acc = super#structure_item item acc in
            self#unflag_derivers;
            acc
        | _ -> super#structure_item item acc

      method! signature_item item acc =
        match item.psig_desc with
        | Psig_type (_, tds) ->
            self#flag_derivers tds;
            let acc = super#signature_item item acc in
            self#unflag_derivers;
            acc
        | _ -> super#signature_item item acc

      method private check ctx attrs acc =
        check_attrs ~json:derives_json ~jsonschema:derives_jsonschema ~ctx
          acc attrs

      method! type_declaration td acc =
        self#check Td td.ptype_attributes (super#type_declaration td acc)

      method! label_declaration ld acc =
        self#check Ld ld.pld_attributes (super#label_declaration ld acc)

      method! constructor_declaration cd acc =
        self#check Cd cd.pcd_attributes
          (super#constructor_declaration cd acc)

      method! row_field rf acc =
        self#check Rtag rf.prf_attributes (super#row_field rf acc)

      method! core_type ct acc =
        self#check Ct ct.ptyp_attributes (super#core_type ct acc)
    end
end

let rules : Driver.Lint_error.t list Ast_traverse.fold list =
  [ No_qualified_shared_attrs.rule; No_misplaced_attrs.rule ]

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
