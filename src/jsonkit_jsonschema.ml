let schema_version = "https://json-schema.org/draft/2020-12/schema"

type t = Jsonkit_jsonschema_classify.t

let classify = Jsonkit_jsonschema_classify.classify
let declassify = Jsonkit_jsonschema_classify.declassify

(* Hoisting of nested [$defs].

   The [jsonschema] deriver emits one self-contained scope per recursive type
   group: an object holding the group's [$defs] next to a [$ref] into them.
   When such a value is nested inside another schema, the deriver marks the
   scope with a ["file://..."] [$id] so that its [$ref]s keep resolving
   locally. A document assembled from several such values therefore repeats
   the same definitions once per use site.

   [make] lifts every one of those scopes into the root [$defs]: a scope is
   an object whose [$defs] is an object and whose [$id] is either absent or
   starts with ["file://"]. Objects carrying any other [$id] are separate
   resources and are left untouched, contents included.

   Definitions are merged by name. A definition equal to the one already
   hoisted under the same name is dropped, provided that every definition it
   refers to is dropped as well, so a scope can never be rewired onto another
   scope's dependencies. Any other clash is renamed to [name_2], [name_3],
   ... and the [$ref]s of its own scope are rewritten accordingly. Names of
   enclosing scopes have priority over nested ones, and names given through
   [~definitions] have priority over everything else. *)

let defs_prefix = "#/$defs/"

(* Splits ["#/$defs/name/rest"] into [Some ("name", "/rest")]. *)
let split_ref ref =
  if String.starts_with ~prefix:defs_prefix ref then
    let start = String.length defs_prefix in
    let rest = String.sub ref start (String.length ref - start) in
    match String.index_opt rest '/' with
    | None -> Some (rest, "")
    | Some i ->
        Some
          (String.sub rest 0 i, String.sub rest i (String.length rest - i))
  else None

let is_local_scope fields =
  match List.assoc_opt "$id" fields with
  | None -> true
  | Some (`String id) -> String.starts_with ~prefix:"file://" id
  | Some _ -> false

let rec rename_refs renames : t -> t = function
  | `Assoc fields when not (is_local_scope fields) -> `Assoc fields
  | `Assoc fields ->
      `Assoc
        (List.map
           (function
             | "$ref", `String ref -> (
                 match split_ref ref with
                 | Some (name, rest) when List.mem_assoc name renames ->
                     ( "$ref",
                       `String
                         (defs_prefix ^ List.assoc name renames ^ rest) )
                 | _ -> "$ref", `String ref)
             | key, value -> key, rename_refs renames value)
           fields)
  | `List values -> `List (List.map (rename_refs renames) values)
  | (`Null | `Bool _ | `Int _ | `Float _ | `String _) as atom -> atom

(* Names of the definitions a schema refers to, foreign resources excluded. *)
let rec referenced_names acc : t -> string list = function
  | `Assoc fields when not (is_local_scope fields) -> acc
  | `Assoc fields ->
      List.fold_left
        (fun acc -> function
          | "$ref", `String ref -> (
              match split_ref ref with
              | Some (name, _) -> name :: acc
              | None -> acc)
          | _, value -> referenced_names acc value)
        acc fields
  | `List values -> List.fold_left referenced_names acc values
  | `Null | `Bool _ | `Int _ | `Float _ | `String _ -> acc

let equal_schema (left : t) (right : t) =
  Jsonkit_json.equal (declassify left) (declassify right)

(* Merges the definitions [own] of one scope into [hoisted]. Returns the
   extended list and the renaming to apply to the rest of the scope.
   [reserved] holds the names of the enclosing scopes, which keep their
   names in preference to this one. *)
let merge_definitions ~reserved hoisted own =
  let own_names = List.map fst own in
  let taken name =
    List.mem_assoc name hoisted || List.mem name reserved
  in
  let equal_to_hoisted (name, schema) =
    match List.assoc_opt name hoisted with
    | Some previous -> equal_schema previous schema
    | None -> false
  in
  (* A definition can only be dropped as a duplicate when every own
     definition it depends on is dropped too; iterate to a fixpoint. *)
  let rec stable_duplicates duplicates =
    let next =
      List.filter
        (fun (_, schema) ->
          List.for_all
            (fun name ->
              (not (List.mem name own_names))
              || List.mem_assoc name duplicates)
            (referenced_names [] schema))
        duplicates
    in
    if List.length next = List.length duplicates then duplicates
    else stable_duplicates next
  in
  let duplicates = stable_duplicates (List.filter equal_to_hoisted own) in
  let kept =
    List.filter
      (fun (name, _) -> not (List.mem_assoc name duplicates))
      own
  in
  let renames, _ =
    List.fold_left
      (fun (renames, used) (name, _) ->
        if not (taken name) then renames, used
        else
          let rec fresh n =
            let candidate = Printf.sprintf "%s_%d" name n in
            if taken candidate || List.mem candidate used then
              fresh (n + 1)
            else candidate
          in
          let fresh = fresh 2 in
          (name, fresh) :: renames, fresh :: used)
      ([], own_names) kept
  in
  let rename =
    match renames with [] -> Fun.id | _ -> rename_refs renames
  in
  let kept =
    List.map
      (fun (name, schema) ->
        ( Option.value ~default:name (List.assoc_opt name renames),
          rename schema ))
      kept
  in
  hoisted @ kept, rename

let rec hoist ~reserved hoisted : t -> (string * t) list * t = function
  | `Assoc fields as schema -> (
      if not (is_local_scope fields) then hoisted, schema
      else
        match List.assoc_opt "$defs" fields with
        | Some (`Assoc own) ->
            let nested_reserved = List.map fst own @ reserved in
            let rest =
              List.filter
                (fun (key, _) -> not (key = "$defs" || key = "$id"))
                fields
            in
            let hoisted, own =
              hoist_fields ~reserved:nested_reserved hoisted own
            in
            let hoisted, rest =
              hoist_fields ~reserved:nested_reserved hoisted rest
            in
            let hoisted, rename =
              merge_definitions ~reserved hoisted own
            in
            hoisted, rename (`Assoc rest)
        | _ ->
            let hoisted, fields = hoist_fields ~reserved hoisted fields in
            hoisted, `Assoc fields)
  | `List values ->
      let hoisted, values =
        List.fold_left_map (hoist ~reserved) hoisted values
      in
      hoisted, `List values
  | (`Null | `Bool _ | `Int _ | `Float _ | `String _) as atom ->
      hoisted, atom

and hoist_fields ~reserved hoisted fields =
  List.fold_left_map
    (fun hoisted (key, value) ->
      let hoisted, value = hoist ~reserved hoisted value in
      hoisted, (key, value))
    hoisted fields

let make ?id ?title ?description ?definitions types =
  let hoisted, types =
    hoist ~reserved:[] (Option.value ~default:[] definitions) types
  in
  let definitions =
    match hoisted, definitions with
    | [], None -> None
    | hoisted, _ -> Some hoisted
  in
  let fields = match types with `Assoc fields -> fields | _ -> [] in
  let metadata =
    List.filter_map
      (fun x -> x)
      [
        Some ("$schema", `String schema_version);
        (match id with
        | None -> None
        | Some id -> Some ("$id", `String id));
        (match title with
        | None -> None
        | Some title -> Some ("title", `String title));
        (match description with
        | None -> None
        | Some description -> Some ("description", `String description));
        (match definitions with
        | None -> None
        | Some defs -> Some ("$defs", `Assoc defs));
      ]
  in
  `Assoc (metadata @ fields)

module Classify = Jsonkit_jsonschema_classify

(* Defines the main jsonschema primitives for Jsonkit *)
module Primitives = Jsonkit_jsonschema_primitives.Jsonkit
module Yojson_primitives = Jsonkit_jsonschema_primitives.Yojson
