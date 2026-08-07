open Jsonkit.Primitives
open Cases

(* [shared/cases.ml] is the source of truth for the case definitions.
   This module only enumerates which generated schemas are included in the shared
   native/Melange snapshot. *)

let schemas =
  [
    Jsonkit.Jsonschema.make Mod1.m_1_jsonschema;
    Jsonkit.Jsonschema.make Mod1.Mod2.m_2_jsonschema;
    Jsonkit.Jsonschema.make with_modules_jsonschema;
    Jsonkit.Jsonschema.make kind_jsonschema;
    Jsonkit.Jsonschema.make poly_kind_jsonschema;
    Jsonkit.Jsonschema.make poly_kind_with_payload_jsonschema;
    Jsonkit.Jsonschema.make poly_inherit_jsonschema;
    Jsonkit.Jsonschema.make event_jsonschema;
    Jsonkit.Jsonschema.make recursive_record_jsonschema;
    Jsonkit.Jsonschema.make recursive_variant_jsonschema;
    Jsonkit.Jsonschema.make tree_jsonschema;
    Jsonkit.Jsonschema.make non_recursive_jsonschema;
    Jsonkit.Jsonschema.make foo_jsonschema;
    Jsonkit.Jsonschema.make bar_jsonschema;
    Jsonkit.Jsonschema.make expr_jsonschema;
    Jsonkit.Jsonschema.make alpha_jsonschema;
    Jsonkit.Jsonschema.make beta_jsonschema;
    Jsonkit.Jsonschema.make node_a_jsonschema;
    Jsonkit.Jsonschema.make recursive_tuple_jsonschema;
    Jsonkit.Jsonschema.make int_tree_jsonschema;
    Jsonkit.Jsonschema.make events_jsonschema;
    Jsonkit.Jsonschema.make eventss_jsonschema;
    Jsonkit.Jsonschema.make event_comment_jsonschema;
    Jsonkit.Jsonschema.make event_comments'_jsonschema;
    Jsonkit.Jsonschema.make event_n_jsonschema;
    Jsonkit.Jsonschema.make events_array_jsonschema;
    Jsonkit.Jsonschema.make numbers_jsonschema;
    Jsonkit.Jsonschema.make opt_jsonschema;
    Jsonkit.Jsonschema.make using_m_jsonschema;
    Jsonkit.Jsonschema.make tuple_with_variant_jsonschema;
    Jsonkit.Jsonschema.make ~id:"https://ahrefs.com/schemas/player_scores"
      ~title:"Player scores"
      ~description:"Object representing player scores"
      ~definitions:[ "numbers", numbers_jsonschema ]
      player_scores_jsonschema;
    Jsonkit.Jsonschema.make t_jsonschema;
    Jsonkit.Jsonschema.make
      ~definitions:[ "shared_address", address_jsonschema ]
      tt_jsonschema;
    Jsonkit.Jsonschema.make c_jsonschema;
    Jsonkit.Jsonschema.make inline_record_with_extra_fields_jsonschema;
    Jsonkit.Jsonschema.make t1_jsonschema;
    Jsonkit.Jsonschema.make t3_jsonschema;
    Jsonkit.Jsonschema.make t4_jsonschema;
    Jsonkit.Jsonschema.make t5_jsonschema;
    Jsonkit.Jsonschema.make t6_jsonschema;
    Jsonkit.Jsonschema.make t7_jsonschema;
    Jsonkit.Jsonschema.make t8_jsonschema;
    Jsonkit.Jsonschema.make t9_jsonschema;
    Jsonkit.Jsonschema.make t10_jsonschema;
    Jsonkit.Jsonschema.make t11_jsonschema;
    Jsonkit.Jsonschema.make nested_obj_jsonschema;
    Jsonkit.Jsonschema.make x_without_extra_jsonschema;
    Jsonkit.Jsonschema.make strict_obj_jsonschema;
    Jsonkit.Jsonschema.make inline_record_disallow_extra_fields_jsonschema;
    Jsonkit.Jsonschema.make
      (generic_link_traffic_jsonschema string_jsonschema);
    Jsonkit.Jsonschema.make string_link_traffic_jsonschema;
    Jsonkit.Jsonschema.make (poly_variant_jsonschema int_jsonschema);
    Jsonkit.Jsonschema.make
      (multi_param_jsonschema int_jsonschema bool_jsonschema);
    Jsonkit.Jsonschema.make (param_list_jsonschema string_jsonschema);
    Jsonkit.Jsonschema.make
      (either_jsonschema int_jsonschema string_jsonschema);
    Jsonkit.Jsonschema.make
      (either_alias_jsonschema int_jsonschema string_jsonschema);
    Jsonkit.Jsonschema.make tool_params_jsonschema;
    Jsonkit.Jsonschema.make described_record_jsonschema;
    Jsonkit.Jsonschema.make with_key_and_desc_jsonschema;
    Jsonkit.Jsonschema.make described_variant_jsonschema;
    Jsonkit.Jsonschema.make described_variant_inline_record_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_record_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_disabled_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_override_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_variant_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_core_type_jsonschema;
    Jsonkit.Jsonschema.make doc_attribute_alias_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_multiline_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_poly_variant_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_multiple_jsonschema;
    Jsonkit.Jsonschema.make doc_comment_poly_variant_override_jsonschema;
    Jsonkit.Jsonschema.make computation_result_jsonschema;
    Jsonkit.Jsonschema.make nullable_fields_jsonschema;
    Jsonkit.Jsonschema.make jsonkit_defaults_jsonschema;
    Jsonkit.Jsonschema.make composing_record_jsonschema;
    Jsonkit.Jsonschema.make with_format_jsonschema;
    Jsonkit.Jsonschema.make with_format_record_jsonschema;
    Jsonkit.Jsonschema.make with_format_variant_jsonschema;
    Jsonkit.Jsonschema.make (grade_jsonschema int_jsonschema);
    Jsonkit.Jsonschema.make two_self_refs_jsonschema;
    Jsonkit.Jsonschema.make
      (filter_jsonschema int_jsonschema string_jsonschema);
    Jsonkit.Jsonschema.make outer_rec_jsonschema;
    Jsonkit.Jsonschema.make
      (bool_filter_jsonschema int_jsonschema string_jsonschema);
    Jsonkit.Jsonschema.make with_maximum_jsonschema;
    Jsonkit.Jsonschema.make with_maximum_record_jsonschema;
    Jsonkit.Jsonschema.make attrs_core_type_jsonschema;
    Jsonkit.Jsonschema.make attrs_record_jsonschema;
    Jsonkit.Jsonschema.make attrs_type_decl_jsonschema;
    Jsonkit.Jsonschema.make minimum_core_type_int_jsonschema;
    Jsonkit.Jsonschema.make minimum_core_type_float_jsonschema;
    Jsonkit.Jsonschema.make minimum_maximum_record_jsonschema;
    Jsonkit.Jsonschema.make minimum_maximum_type_decl_int_jsonschema;
    Jsonkit.Jsonschema.make minimum_maximum_type_decl_float_jsonschema;
    Jsonkit.Jsonschema.make minimum_maximum_variant_jsonschema;
    Jsonkit.Jsonschema.make default_value_jsonschema;
    Jsonkit.Jsonschema.make default_with_module_type_jsonschema;
    Jsonkit.Jsonschema.make outer_default_record_with_option_jsonschema;
    Jsonkit.Jsonschema.make compact_variants_jsonschema;
    Jsonkit.Jsonschema.make compact_poly_variants_jsonschema;
    Jsonkit.Jsonschema.make Nonrec_type_alias.foo_jsonschema;
    Jsonkit.Jsonschema.make Nonrec_type_alias.X.foo_jsonschema;
    Jsonkit.Jsonschema.make Recursive_shapes.a_jsonschema;
    Jsonkit.Jsonschema.make Recursive_shapes.b_jsonschema;
    Jsonkit.Jsonschema.make Recursive_shapes.t_jsonschema;
    Jsonkit.Jsonschema.make
      (Recursive_shapes.lst_jsonschema int_jsonschema);
    Jsonkit.Jsonschema.make
      (Recursive_shapes.tree_jsonschema string_jsonschema);
    Jsonkit.Jsonschema.make
      (Recursive_shapes.forest_jsonschema string_jsonschema);
  ]

let snapshot =
  `Assoc
    [
      "$schema", `String Jsonkit.Jsonschema.schema_version;
      "oneOf", `List schemas;
    ]

let snapshot_string = Schema_snapshot.json_to_string snapshot
