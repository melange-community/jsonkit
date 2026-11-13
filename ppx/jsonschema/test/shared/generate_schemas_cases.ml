open Jsonkit_jsonschema.Primitives
open Cases

(* [shared/cases.ml] is the source of truth for the case definitions.
   This module only enumerates which generated schemas are included in the shared
   native/Melange snapshot. *)

let schemas =
  [
    Jsonkit_jsonschema.make Mod1.m_1_jsonschema;
    Jsonkit_jsonschema.make Mod1.Mod2.m_2_jsonschema;
    Jsonkit_jsonschema.make with_modules_jsonschema;
    Jsonkit_jsonschema.make kind_jsonschema;
    Jsonkit_jsonschema.make poly_kind_jsonschema;
    Jsonkit_jsonschema.make poly_kind_with_payload_jsonschema;
    Jsonkit_jsonschema.make poly_inherit_jsonschema;
    Jsonkit_jsonschema.make event_jsonschema;
    Jsonkit_jsonschema.make recursive_record_jsonschema;
    Jsonkit_jsonschema.make recursive_variant_jsonschema;
    Jsonkit_jsonschema.make tree_jsonschema;
    Jsonkit_jsonschema.make non_recursive_jsonschema;
    Jsonkit_jsonschema.make foo_jsonschema;
    Jsonkit_jsonschema.make bar_jsonschema;
    Jsonkit_jsonschema.make expr_jsonschema;
    Jsonkit_jsonschema.make alpha_jsonschema;
    Jsonkit_jsonschema.make beta_jsonschema;
    Jsonkit_jsonschema.make node_a_jsonschema;
    Jsonkit_jsonschema.make recursive_tuple_jsonschema;
    Jsonkit_jsonschema.make int_tree_jsonschema;
    Jsonkit_jsonschema.make events_jsonschema;
    Jsonkit_jsonschema.make eventss_jsonschema;
    Jsonkit_jsonschema.make event_comment_jsonschema;
    Jsonkit_jsonschema.make event_comments'_jsonschema;
    Jsonkit_jsonschema.make event_n_jsonschema;
    Jsonkit_jsonschema.make events_array_jsonschema;
    Jsonkit_jsonschema.make numbers_jsonschema;
    Jsonkit_jsonschema.make opt_jsonschema;
    Jsonkit_jsonschema.make using_m_jsonschema;
    Jsonkit_jsonschema.make tuple_with_variant_jsonschema;
    Jsonkit_jsonschema.make ~id:"https://ahrefs.com/schemas/player_scores"
      ~title:"Player scores"
      ~description:"Object representing player scores"
      ~definitions:[ "numbers", numbers_jsonschema ]
      player_scores_jsonschema;
    Jsonkit_jsonschema.make t_jsonschema;
    Jsonkit_jsonschema.make
      ~definitions:[ "shared_address", address_jsonschema ]
      tt_jsonschema;
    Jsonkit_jsonschema.make c_jsonschema;
    Jsonkit_jsonschema.make inline_record_with_extra_fields_jsonschema;
    Jsonkit_jsonschema.make t1_jsonschema;
    Jsonkit_jsonschema.make t3_jsonschema;
    Jsonkit_jsonschema.make t4_jsonschema;
    Jsonkit_jsonschema.make t5_jsonschema;
    Jsonkit_jsonschema.make t6_jsonschema;
    Jsonkit_jsonschema.make t7_jsonschema;
    Jsonkit_jsonschema.make t8_jsonschema;
    Jsonkit_jsonschema.make t9_jsonschema;
    Jsonkit_jsonschema.make t10_jsonschema;
    Jsonkit_jsonschema.make t11_jsonschema;
    Jsonkit_jsonschema.make nested_obj_jsonschema;
    Jsonkit_jsonschema.make x_without_extra_jsonschema;
    Jsonkit_jsonschema.make strict_obj_jsonschema;
    Jsonkit_jsonschema.make inline_record_disallow_extra_fields_jsonschema;
    Jsonkit_jsonschema.make
      (generic_link_traffic_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make string_link_traffic_jsonschema;
    Jsonkit_jsonschema.make (poly_variant_jsonschema int_jsonschema);
    Jsonkit_jsonschema.make
      (multi_param_jsonschema int_jsonschema bool_jsonschema);
    Jsonkit_jsonschema.make (param_list_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make
      (either_jsonschema int_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make
      (either_alias_jsonschema int_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make tool_params_jsonschema;
    Jsonkit_jsonschema.make described_record_jsonschema;
    Jsonkit_jsonschema.make with_key_and_desc_jsonschema;
    Jsonkit_jsonschema.make described_variant_jsonschema;
    Jsonkit_jsonschema.make described_variant_inline_record_jsonschema;
    Jsonkit_jsonschema.make doc_comment_record_jsonschema;
    Jsonkit_jsonschema.make doc_comment_disabled_jsonschema;
    Jsonkit_jsonschema.make doc_comment_override_jsonschema;
    Jsonkit_jsonschema.make doc_comment_variant_jsonschema;
    Jsonkit_jsonschema.make doc_comment_core_type_jsonschema;
    Jsonkit_jsonschema.make doc_attribute_alias_jsonschema;
    Jsonkit_jsonschema.make doc_comment_multiline_jsonschema;
    Jsonkit_jsonschema.make doc_comment_poly_variant_jsonschema;
    Jsonkit_jsonschema.make doc_comment_multiple_jsonschema;
    Jsonkit_jsonschema.make doc_comment_poly_variant_override_jsonschema;
    Jsonkit_jsonschema.make computation_result_jsonschema;
    Jsonkit_jsonschema.make nullable_fields_jsonschema;
    Jsonkit_jsonschema.make jsonkit_defaults_jsonschema;
    Jsonkit_jsonschema.make composing_record_jsonschema;
    Jsonkit_jsonschema.make with_format_jsonschema;
    Jsonkit_jsonschema.make with_format_record_jsonschema;
    Jsonkit_jsonschema.make with_format_variant_jsonschema;
    Jsonkit_jsonschema.make (grade_jsonschema int_jsonschema);
    Jsonkit_jsonschema.make two_self_refs_jsonschema;
    Jsonkit_jsonschema.make
      (filter_jsonschema int_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make outer_rec_jsonschema;
    Jsonkit_jsonschema.make
      (bool_filter_jsonschema int_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make with_maximum_jsonschema;
    Jsonkit_jsonschema.make with_maximum_record_jsonschema;
    Jsonkit_jsonschema.make attrs_core_type_jsonschema;
    Jsonkit_jsonschema.make attrs_record_jsonschema;
    Jsonkit_jsonschema.make attrs_type_decl_jsonschema;
    Jsonkit_jsonschema.make minimum_core_type_int_jsonschema;
    Jsonkit_jsonschema.make minimum_core_type_float_jsonschema;
    Jsonkit_jsonschema.make minimum_maximum_record_jsonschema;
    Jsonkit_jsonschema.make minimum_maximum_type_decl_int_jsonschema;
    Jsonkit_jsonschema.make minimum_maximum_type_decl_float_jsonschema;
    Jsonkit_jsonschema.make minimum_maximum_variant_jsonschema;
    Jsonkit_jsonschema.make default_value_jsonschema;
    Jsonkit_jsonschema.make default_with_module_type_jsonschema;
    Jsonkit_jsonschema.make outer_default_record_with_option_jsonschema;
    Jsonkit_jsonschema.make compact_variants_jsonschema;
    Jsonkit_jsonschema.make compact_poly_variants_jsonschema;
    Jsonkit_jsonschema.make Nonrec_type_alias.foo_jsonschema;
    Jsonkit_jsonschema.make Nonrec_type_alias.X.foo_jsonschema;
    Jsonkit_jsonschema.make Recursive_shapes.a_jsonschema;
    Jsonkit_jsonschema.make Recursive_shapes.b_jsonschema;
    Jsonkit_jsonschema.make Recursive_shapes.t_jsonschema;
    Jsonkit_jsonschema.make
      (Recursive_shapes.lst_jsonschema int_jsonschema);
    Jsonkit_jsonschema.make
      (Recursive_shapes.tree_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make
      (Recursive_shapes.forest_jsonschema string_jsonschema);
    Jsonkit_jsonschema.make same_name_jsonschema;
    Jsonkit_jsonschema.make same_ref_jsonschema;
    Jsonkit_jsonschema.make described_pair_jsonschema;
    Jsonkit_jsonschema.make wrapped_a_jsonschema;
    Jsonkit_jsonschema.make wrapped_b_jsonschema;
    Jsonkit_jsonschema.make (described_box_jsonschema int_jsonschema);
    Jsonkit_jsonschema.make described_tag_jsonschema;
    Hoist.nested_scope;
    Hoist.mixed_collision;
    Hoist.user_resource;
  ]

let snapshot =
  `Assoc
    [
      "$schema", `String Jsonkit_jsonschema.schema_version;
      "oneOf", `List schemas;
    ]

let snapshot_string = Schema_snapshot.json_to_string snapshot
