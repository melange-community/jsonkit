open Ppxlib
open Ast_builder.Default

let const ~loc value =
  [%expr `Assoc [ "const", `String [%e estring ~loc value] ]]

let ref_target ~loc type_name = estring ~loc ("#/$defs/" ^ type_name)

let type_ref ~loc type_name =
  [%expr `Assoc [ "$ref", `String [%e ref_target ~loc type_name] ]]

let definitions_ref ~loc type_name definitions =
  [%expr
    `Assoc
      [
        "$defs", `Assoc [%e definitions];
        "$ref", `String [%e ref_target ~loc type_name];
      ]]

let anyOf ~loc values =
  [%expr `Assoc [ "anyOf", `List [%e elist ~loc values] ]]

let tuple ~loc elements =
  [%expr
    `Assoc
      [
        "type", `String "array";
        "prefixItems", `List [%e elist ~loc elements];
        "unevaluatedItems", `Bool false;
        "minItems", `Int [%e eint ~loc (List.length elements)];
        "maxItems", `Int [%e eint ~loc (List.length elements)];
      ]]

let annotation ~loc (name, value) schema =
  match schema with
  | [%expr `Assoc [%e? fields]] ->
      [%expr `Assoc (([%e estring ~loc name], [%e value]) :: [%e fields])]
  | s ->
      [%expr
        match [%e s] with
        | `Assoc ppx_fields ->
            `Assoc (([%e estring ~loc name], [%e value]) :: ppx_fields)
        | ppx_other -> ppx_other]

let format ~loc format =
  annotation ~loc ("format", [%expr `String [%e estring ~loc format]])

let maximum ~loc maximum = annotation ~loc ("maximum", maximum)
let minimum ~loc minimum = annotation ~loc ("minimum", minimum)

let description ~loc description schema_expr =
  annotation ~loc
    ("description", [%expr `String [%e estring ~loc description]])
    schema_expr

let variants ~loc ?(compact_variants = false) constrs =
  let opt_description ~loc desc schema =
    match desc with Some d -> description ~loc d schema | None -> schema
  in
  anyOf ~loc
    (List.map
       (function
         | `Tag (name, typs, desc) ->
             let schema =
               if compact_variants && typs = [] then const ~loc name
               else tuple ~loc (const ~loc name :: typs)
             in
             opt_description ~loc desc schema
         | `Inherit typ -> typ)
       constrs)

module Annotation = struct
  let is_string_type core_type =
    match core_type with
    | [%type: string]
    | [%type: bytes]
    | [%type: string option]
    | [%type: bytes option] ->
        true
    | _ -> false

  let ensure_string_type ~attribute_name core_type =
    if not (is_string_type core_type) then
      Location.raise_errorf ~loc:core_type.ptyp_loc
        "%s can only be applied to string or bytes types" attribute_name

  let numeric_json ~loc ~attribute_name core_type value =
    match core_type with
    | [%type: int] | [%type: int32] | [%type: nativeint] ->
        [%expr `Int [%e value]]
    | [%type: float] -> [%expr `Float [%e value]]
    | _ ->
        Location.raise_errorf ~loc:core_type.ptyp_loc
          "%s can only be applied to numeric types" attribute_name

  let is_numeric_literal core_type expr =
    match core_type, expr.pexp_desc with
    | ( ([%type: int] | [%type: int32] | [%type: nativeint]),
        Pexp_constant (Pconst_integer _) ) ->
        true
    | [%type: float], Pexp_constant (Pconst_float _) -> true
    | _ -> false

  let add_format ~loc core_type (fmt : string Location.loc) schema =
    ensure_string_type ~attribute_name:"[@jsonschema.format]" core_type;
    format ~loc fmt.txt schema

  let add_bound ~loc ~key ~attribute_name core_type expr schema =
    if not (is_numeric_literal core_type expr) then
      Location.raise_errorf ~loc:core_type.ptyp_loc
        "%s can only be applied to numeric types" attribute_name;
    annotation ~loc
      (key, numeric_json ~loc ~attribute_name core_type expr)
      schema

  let add_maximum ~loc =
    add_bound ~loc ~key:"maximum" ~attribute_name:"[@jsonschema.maximum]"

  let add_minimum ~loc =
    add_bound ~loc ~key:"minimum" ~attribute_name:"[@jsonschema.minimum]"

  let rec serialize_expr ~loc ct default_value_expr =
    match ct with
    | [%type: int] | [%type: int32] | [%type: nativeint] ->
        [%expr `Int [%e default_value_expr]]
    | [%type: float] -> [%expr `Float [%e default_value_expr]]
    | [%type: string] | [%type: bytes] ->
        [%expr `String [%e default_value_expr]]
    | [%type: bool] -> [%expr `Bool [%e default_value_expr]]
    | [%type: [%t? t] option] ->
        [%expr
          match [%e default_value_expr] with
          | None -> `Null
          | Some ppx_opt_v -> [%e serialize_expr ~loc t [%expr ppx_opt_v]]]
    | [%type: [%t? t] list] ->
        [%expr
          `List
            (Stdlib.List.map
               (fun ppx_item ->
                 [%e serialize_expr ~loc t [%expr ppx_item]])
               [%e default_value_expr])]
    | [%type: [%t? t] array] ->
        [%expr
          `List
            (Stdlib.Array.to_list
               (Stdlib.Array.map
                  (fun ppx_item ->
                    [%e serialize_expr ~loc t [%expr ppx_item]])
                  [%e default_value_expr]))]
    | { ptyp_desc = Ptyp_tuple types; _ } ->
        let vars =
          List.mapi (fun i _ -> Printf.sprintf "ppx_tuple_%d" i) types
        in
        let pats =
          List.map (fun v -> ppat_var ~loc { txt = v; loc }) vars
        in
        let exprs =
          List.map2
            (fun t v -> serialize_expr ~loc t (evar ~loc v))
            types vars
        in
        [%expr
          match [%e default_value_expr] with
          | [%p ppat_tuple ~loc pats] -> `List [%e elist ~loc exprs]]
    | { ptyp_desc = Ptyp_var _; _ } ->
        Location.raise_errorf ~loc:ct.ptyp_loc
          "[@jsonschema.default] cannot be used on a field whose type is \
           a type variable"
    | { ptyp_desc = Ptyp_constr (id, args); _ } ->
        let arg_serializers =
          List.map
            (fun arg ->
              [%expr
                fun ppx_x ->
                  Jsonkit.Jsonschema.declassify
                    [%e serialize_expr ~loc arg [%expr ppx_x]]])
            args
        in
        let to_json_expr =
          type_constr_conv ~loc id
            ~f:(fun s ->
              if String.equal s "t" then "to_json" else s ^ "_to_json")
            arg_serializers
        in
        [%expr
          Jsonkit.Jsonschema.classify
            ([%e to_json_expr] [%e default_value_expr])]
    | _ ->
        Location.raise_errorf ~loc:ct.ptyp_loc
          "[@jsonschema.default] cannot serialize this type. For \
           non-primitive types, ensure a '<type>_to_json' function is in \
           scope (e.g., add [@@@@deriving json] to the type definition)"

  let add_default ~loc core_type expr schema =
    let json_value =
      match expr.pexp_desc with
      | Pexp_construct ({ txt = Lident "[]"; _ }, None) ->
          [%expr `List []]
      | Pexp_construct ({ txt = Lident "None"; _ }, None) -> [%expr `Null]
      | _ ->
          let base_type =
            match core_type with [%type: [%t? t] option] -> t | t -> t
          in
          serialize_expr ~loc base_type expr
    in
    annotation ~loc ("default", json_value) schema

  let add_attrs_record ~loc ?core_type attrs schema =
    let require_core_type field =
      match core_type with
      | Some t -> t
      | None ->
          Location.raise_errorf ~loc
            "[@jsonschema.attrs] '%s' requires a type context (use the \
             individual [@jsonschema.%s] attribute instead)"
            field field
    in
    let string_literal ~field value =
      match value.pexp_desc with
      | Pexp_constant (Pconst_string (s, _, _)) -> s
      | _ ->
          Location.raise_errorf ~loc:value.pexp_loc
            "[@jsonschema.attrs] '%s' must be a string literal" field
    in
    let bound ~key value schema =
      let ct = require_core_type key in
      let attribute_name =
        Printf.sprintf "[@jsonschema.attrs] '%s'" key
      in
      annotation ~loc
        (key, numeric_json ~loc ~attribute_name ct value)
        schema
    in
    match attrs with
    | None -> schema
    | Some expr -> (
        match expr.pexp_desc with
        | Pexp_record (fields, None) ->
            List.fold_left
              (fun schema ({ txt = label; loc = label_loc }, value) ->
                match label with
                | Lident "description" ->
                    description ~loc
                      (string_literal ~field:"description" value)
                      schema
                | Lident "format" ->
                    let ct = require_core_type "format" in
                    let s = string_literal ~field:"format" value in
                    ensure_string_type
                      ~attribute_name:"[@jsonschema.attrs] 'format'" ct;
                    format ~loc s schema
                | Lident "maximum" -> bound ~key:"maximum" value schema
                | Lident "minimum" -> bound ~key:"minimum" value schema
                | Lident name ->
                    Location.raise_errorf ~loc:label_loc
                      "[@jsonschema.attrs] unknown field: '%s'" name
                | _ ->
                    Location.raise_errorf ~loc:label_loc
                      "[@jsonschema.attrs] expected a simple field name")
              schema fields
        | _ ->
            Location.raise_errorf ~loc:expr.pexp_loc
              "[@jsonschema.attrs] expects a record expression: { field \
               = value; ... }")

  type t = {
    description : string Location.loc option;
    format : string Location.loc option;
    maximum : expression option;
    minimum : expression option;
    default : expression option;
    attrs : expression option;
  }

  let none =
    {
      description = None;
      format = None;
      maximum = None;
      minimum = None;
      default = None;
      attrs = None;
    }

  let apply ~loc ?core_type t schema =
    let without_core_type value f schema =
      match value with Some v -> f v schema | None -> schema
    in
    let with_core_type ~attribute_name value f schema =
      match core_type, value with
      | Some ct, Some v -> f ct v schema
      | None, Some _ ->
          Location.raise_errorf ~loc
            "%s requires a type declaration with a manifest (an alias), \
             not a record or variant"
            attribute_name
      | _, None -> schema
    in
    schema
    |> without_core_type t.description (fun d s ->
        description ~loc d.txt s)
    |> with_core_type ~attribute_name:"[@jsonschema.format]" t.format
         (add_format ~loc)
    |> with_core_type ~attribute_name:"[@jsonschema.maximum]" t.maximum
         (add_maximum ~loc)
    |> with_core_type ~attribute_name:"[@jsonschema.minimum]" t.minimum
         (add_minimum ~loc)
    |> with_core_type ~attribute_name:"[@jsonschema.default]" t.default
         (add_default ~loc)
    |> add_attrs_record ~loc ?core_type t.attrs
end
