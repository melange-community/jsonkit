open Printf
open Ppxlib
open Ast_builder.Default
open StdLabels
open Expansion_helpers

module Lid = struct
  let flatten =
    let rec flat accu = function
      | Lident s -> s :: accu
      | Ldot (lid, s) -> flat (s :: accu) lid
      | Lapply (_, _) -> failwith "Longident.flat"
    in
    fun lid -> flat [] lid

  let unflatten l =
    match l with
    | [] -> None
    | hd :: tl ->
        Some
          (List.fold_left
             ~f:(fun p s -> Ldot (p, s))
             ~init:(Lident hd) tl)
end

let not_supportedf ~loc fmt =
  ksprintf (Location.raise_errorf ~loc "%s are not supported") fmt

let not_supported ~loc s = not_supportedf ~loc "%s" s
let map_loc f a_loc = { a_loc with txt = f a_loc.txt }

let lident_with_optional_open ?opn label =
  match opn with
  | Some { txt = lid; _ } -> Longident.Ldot (lid, label)
  | None -> lident label

let gen_bindings ~loc prefix n =
  List.split
    (List.init ~len:n ~f:(fun i ->
         let id = sprintf "%s_%i" prefix i in
         let patt = ppat_var ~loc { loc; txt = id } in
         let expr = pexp_ident ~loc { loc; txt = lident id } in
         patt, expr))

let gen_pat_tuple ~loc prefix n =
  let patts, exprs = gen_bindings ~loc prefix n in
  ppat_tuple ~loc patts, exprs

let gen_pat_list ~loc prefix n =
  let patts, exprs = gen_bindings ~loc prefix n in
  let patt =
    List.fold_left (List.rev patts)
      ~init:[%pat? []]
      ~f:(fun prev patt -> [%pat? [%p patt] :: [%p prev]])
  in
  patt, exprs

let gen_pat_record ~loc prefix keys =
  let xs =
    List.map keys ~f:(fun (key : label loc) ->
        let { txt; loc } = key in
        let id = sprintf "%s_%s" prefix txt in
        let patt = ppat_var ~loc { loc; txt = id } in
        let expr = pexp_ident ~loc { loc; txt = lident id } in
        (map_loc lident key, patt), expr)
  in
  ppat_record ~loc (List.map xs ~f:fst) Closed, List.map xs ~f:snd

let labeled_tuple_arg_label (n : label loc) =
  match int_of_string_opt n.txt with Some _ -> None | None -> Some n.txt

let gen_pat_labeled_tuple ~loc prefix fs =
  let xs =
    List.map fs ~f:(fun (n, _t) ->
        let id = sprintf "%s_%s" prefix n.txt in
        let patt = ppat_var ~loc { loc = n.loc; txt = id } in
        let expr = pexp_ident ~loc { loc = n.loc; txt = lident id } in
        (labeled_tuple_arg_label n, patt), expr)
  in
  ppat_labeled_tuple ~loc (List.map xs ~f:fst) Closed, List.map xs ~f:snd

let ( --> ) pc_lhs pc_rhs = { pc_lhs; pc_rhs; pc_guard = None }
let derive_of_label name = mangle (Suffix name)
let derive_of_longident name = mangle_lid (Suffix name)

let ederiver name (lid : Longident.t loc) =
  pexp_ident ~loc:lid.loc (map_loc (derive_of_longident name) lid)

type deriver =
  | As_fun of (expression -> expression)
  | As_val of expression

let as_val ~loc deriver x =
  match deriver with As_fun f -> f x | As_val f -> [%expr [%e f] [%e x]]

let as_fun ~loc deriver =
  match deriver with
  | As_fun f -> [%expr fun x -> [%e f [%expr x]]]
  | As_val f -> f
