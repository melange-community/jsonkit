val const : loc:Warnings.loc -> string -> Ppxlib.expression
val type_ref : loc:Warnings.loc -> string -> Ppxlib.expression

val definitions_ref :
  loc:Warnings.loc -> string -> Ppxlib.expression -> Ppxlib.expression

val anyOf :
  loc:Warnings.loc -> Ppxlib.expression list -> Ppxlib.expression

val tuple :
  loc:Warnings.loc -> Ppxlib.expression list -> Ppxlib.expression

val annotation :
  loc:Warnings.loc ->
  string * Ppxlib.expression ->
  Ppxlib.expression ->
  Ppxlib.expression

val format :
  loc:Warnings.loc -> string -> Ppxlib.expression -> Ppxlib.expression

val maximum :
  loc:Warnings.loc ->
  Ppxlib.expression ->
  Ppxlib.expression ->
  Ppxlib.expression

val minimum :
  loc:Warnings.loc ->
  Ppxlib.expression ->
  Ppxlib.expression ->
  Ppxlib.expression

val description :
  loc:Warnings.loc -> string -> Ppxlib.expression -> Ppxlib.expression

val variants :
  loc:Warnings.loc ->
  ?compact_variants:bool ->
  [< `Inherit of Ppxlib.expression
  | `Tag of string * Ppxlib.expression list * string option ]
  list ->
  Ppxlib.expression

module Annotation : sig
  type t = {
    description : string Location.loc option;
    format : string Location.loc option;
    maximum : Ppxlib.expression option;
    minimum : Ppxlib.expression option;
    default : Ppxlib.expression option;
    attrs : Ppxlib.expression option;
  }

  val none : t

  val apply :
    loc:Warnings.loc ->
    ?core_type:Ppxlib.core_type ->
    t ->
    Ppxlib.expression ->
    Ppxlib.expression
end
