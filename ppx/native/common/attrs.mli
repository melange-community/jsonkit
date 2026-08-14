open Ppxlib

(** Attribute declarations for the [@@deriving json] and
    [@@deriving jsonschema] derivers. The [Common] functor that generates
    the attributes shared by both is an implementation detail and is
    intentionally not exposed. *)

module Json : sig
  type case_ctx =
    [ `Variant_ctx of constructor_declaration
    | `Polyvariant_ctx of row_field ]
  (** A variant case as seen by the attribute readers below: either a
      regular variant constructor or a polymorphic-variant tag. *)

  val vcs_attr_json_name :
    ?mark_as_seen:bool -> case_ctx -> string Location.loc option
  (** Resolve [@json.name] off a variant case, whether a regular
      constructor or a polymorphic-variant tag. *)

  val vcs_attr_json_allow_any : ?mark_as_seen:bool -> case_ctx -> bool
  (** [@json.allow_any] on a variant case. *)

  val vcs_attr_json_catch_all : ?mark_as_seen:bool -> case_ctx -> bool
  (** [@json.catch_all] on a variant case. *)

  val is_compact_variants : type_declaration -> bool
  (** [@@json.compact_variants] on a type declaration. *)

  val ld_attr_json_key :
    ?mark_as_seen:bool -> label_declaration -> string Location.loc option
  (** [@json.key "..."] on a record field. *)

  val td_allow_extra_fields : type_declaration -> bool
  (** Whether extra fields are permitted, resolving
      [@json.allow_extra_fields] against [@json.disallow_extra_fields]
      (raises on conflict). *)

  val cd_allow_extra_fields : constructor_declaration -> bool

  val ld_attr_default : label_declaration -> expression option
  (** The default value for a record field: [@json.default expr], or
      [None] for a [@json.option] field. *)

  val ld_drop_default :
    label_declaration ->
    [ `No
    | `Drop_option
    | `Drop_default of expression * expression
    | `Drop_default_if_json_equal of expression ]
  (** Resolve the [@json.drop_default] /
      [@json.drop_default_if_json_equal] family (together with [@option] /
      [@default]) into a drop policy. *)

  val attributes : Attribute.packed list
  (** All [json] attributes, for [Deriving.Generator.V2.make ~attributes].
  *)
end

module Jsonschema : sig
  type config = {
    polymorphic_variant_tuple : bool;
        (** Preserve the implicit tuple in a polymorphic variant. This
            option breaks compatibility with yojson derivers. *)
    ocaml_doc : bool;
        (** Use [ocaml.doc] attributes (i.e. [(** ... *)] comments) as a
            fallback for [[@jsonschema.description]] when the explicit
            annotation is absent. *)
  }

  val key : (label_declaration, string Location.loc) Attribute.t
  val ref : (label_declaration, string Location.loc) Attribute.t

  val variant_name :
    (constructor_declaration, string Location.loc) Attribute.t

  val polymorphic_variant_name :
    (row_field, string Location.loc) Attribute.t

  val td_allow_extra_fields : (type_declaration, unit) Attribute.t
  val cd_allow_extra_fields : (constructor_declaration, unit) Attribute.t
  val td_disallow_extra_fields : (type_declaration, unit) Attribute.t

  val cd_disallow_extra_fields :
    (constructor_declaration, unit) Attribute.t

  val option : label_declaration Attribute.flag
  val td_format : (type_declaration, string Location.loc) Attribute.t
  val ld_format : (label_declaration, string Location.loc) Attribute.t
  val ct_format : (core_type, string Location.loc) Attribute.t
  val td_maximum : (type_declaration, expression) Attribute.t
  val ld_maximum : (label_declaration, expression) Attribute.t
  val ct_maximum : (core_type, expression) Attribute.t
  val td_minimum : (type_declaration, expression) Attribute.t
  val ld_minimum : (label_declaration, expression) Attribute.t
  val ct_minimum : (core_type, expression) Attribute.t
  val ct_attrs : (core_type, expression) Attribute.t
  val td_attrs : (type_declaration, expression) Attribute.t
  val ld_attrs : (label_declaration, expression) Attribute.t
  val ld_default : (label_declaration, expression) Attribute.t
  val td_compact_variants : type_declaration Attribute.flag

  val ld_description :
    ocaml_doc:bool -> label_declaration -> string Location.loc option
  (** [ld_description], [td_description], [cd_description],
      [ct_description] and [rtag_description] resolve a description from
      [[@jsonschema.description "..."]]. When [ocaml_doc] is [true] and
      the explicit annotation is absent, they fall back to an [ocaml.doc]
      attribute (i.e. a [(** ... *)] comment) on the same node. *)

  val td_description :
    ocaml_doc:bool -> type_declaration -> string Location.loc option

  val cd_description :
    ocaml_doc:bool ->
    constructor_declaration ->
    string Location.loc option

  val ct_description :
    ocaml_doc:bool -> core_type -> string Location.loc option

  val rtag_description :
    ocaml_doc:bool -> row_field -> string Location.loc option

  val attributes : Attribute.packed list
  (** All [jsonschema] attributes, for
      [Deriving.Generator.V2.make ~attributes]. *)

  val args : unit -> (bool -> bool -> 'a, 'a) Deriving.Args.t
end
