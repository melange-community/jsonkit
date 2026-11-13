(* Composes derived schemas into one with a single root [$defs]. *)

let defs_prefix = "#/$defs/"

let drop_prefix ~prefix s =
  let n = String.length prefix in
  if String.length s >= n && String.equal (String.sub s 0 n) prefix then
    Some (String.sub s n (String.length s - n))
  else None

module Term = struct
  type reference =
    | Local of int  (** The definition numbered [n] in the scope. *)
    | Member of { path : string; name : string }
        (** A member of the recursive group defined in module [path]. *)
    | Free of string  (** A definition nothing in scope defines. *)

  (* A ref can only be the [$ref] field of an object. *)
  type t =
    | Json of Jsonkit_jsonschema_classify.t
    | List of t list
    | Object of field list

  and field = Field of string * t | Ref of reference

  let member_prefix = "\000"

  let field_of_ref ref =
    match drop_prefix ~prefix:defs_prefix ref with
    | None -> Field ("$ref", Json (`String ref))
    | Some name -> (
        match drop_prefix ~prefix:member_prefix name with
        | None -> Ref (Free name)
        | Some member ->
            let dot = String.rindex member '.' in
            Ref
              (Member
                 {
                   path = String.sub member 0 dot;
                   name =
                     String.sub member (dot + 1)
                       (String.length member - dot - 1);
                 }))

  let rec to_json name_of : t -> Jsonkit_jsonschema_classify.t = function
    | Json json -> json
    | List values -> `List (List.map (to_json name_of) values)
    | Object fields ->
        `Assoc
          (List.map
             (function
               | Field (key, value) -> key, to_json name_of value
               | Ref reference ->
                   ( "$ref",
                     `String
                       (defs_prefix
                       ^
                       match reference with
                       | Local id -> name_of id
                       | Member { path; name } ->
                           member_prefix ^ path ^ "." ^ name
                       | Free name -> name) ))
             fields)

  let rec map_refs f = function
    | Json json -> Json json
    | List values -> List (List.map (map_refs f) values)
    | Object fields ->
        Object
          (List.map
             (function
               | Field (key, value) -> Field (key, map_refs f value)
               | Ref reference -> Ref (f reference))
             fields)

  let subst lookup =
    map_refs (fun reference ->
        Option.fold ~none:reference
          ~some:(fun id -> Local id)
          (lookup reference))

  let refs term =
    let rec collect refs = function
      | Json _ -> refs
      | List values -> List.fold_left collect refs values
      | Object fields ->
          List.fold_left
            (fun refs -> function
              | Field (_, value) -> collect refs value
              | Ref reference -> reference :: refs)
            refs fields
    in
    List.rev (collect [] term)

  let local_ids =
    List.filter_map (function
      | Local id -> Some id
      | Member _ | Free _ -> None)
end

(* A definition in a scope. *)
module Definition = struct
  type t = { id : int; name : string; body : Term.t }

  module Int_map = Map.Make (Int)
  module Int_set = Set.Make (Int)
  module String_map = Map.Make (String)
  module String_set = Set.Make (String)

  (* [cache]: the [$defs] lists already numbered, parsed once each. *)
  type cached = {
    defs : (string * Jsonkit_jsonschema_classify.t) list;
    ids : int String_map.t;
  }

  type state = { next_id : int; cache : cached list; nodes : t list }

  let empty = { next_id = 0; cache = []; nodes = [] }

  let rec parse state : Jsonkit_jsonschema_classify.t -> state * Term.t =
    function
    | `Assoc fields as json when List.mem_assoc "$id" fields ->
        state, Term.Json json
    | `Assoc fields -> (
        match List.assoc_opt "$defs" fields with
        | Some (`Assoc defs) ->
            enter_scope state defs (fun state ->
                parse_fields state (List.remove_assoc "$defs" fields))
        | Some _ | None -> parse_fields state fields)
    | `List values ->
        let state, values = List.fold_left_map parse state values in
        state, Term.List values
    | (`Null | `Bool _ | `Int _ | `Float _ | `String _) as atom ->
        state, Term.Json atom

  and parse_fields state fields =
    let state, fields =
      List.fold_left_map
        (fun state -> function
          | "$ref", `String ref -> state, Term.field_of_ref ref
          | key, value ->
              let state, value = parse state value in
              state, Term.Field (key, value))
        state fields
    in
    state, Term.Object fields

  and enter_scope state defs content =
    let outer = state.nodes in
    let state = { state with nodes = [] } in
    let state, ids =
      match
        List.find_opt
          (fun cached -> cached.defs == defs || cached.defs = defs)
          state.cache
      with
      | Some cached -> state, cached.ids
      | None ->
          let numbered =
            List.mapi
              (fun i (name, schema) -> name, schema, state.next_id + i)
              defs
          in
          let ids =
            String_map.of_seq
              (Seq.map
                 (fun (name, _, id) -> name, id)
                 (List.to_seq numbered))
          in
          let state, own =
            List.fold_left_map
              (fun state (name, schema, id) ->
                let state, body = parse state schema in
                state, { id; name; body })
              { state with next_id = state.next_id + List.length defs }
              numbered
          in
          let nodes = List.rev_append own state.nodes in
          let closed =
            List.for_all
              (fun { body; _ } ->
                List.for_all
                  (function
                    | Term.Free name -> String_map.mem name ids
                    | Local _ | Member _ -> true)
                  (Term.refs body))
              nodes
          in
          ( {
              state with
              nodes;
              cache =
                (if closed then { defs; ids } :: state.cache
                 else state.cache);
            },
            ids )
    in
    let subst =
      Term.subst (function
        | Free name -> String_map.find_opt name ids
        | Local _ | Member _ -> None)
    in
    let state, content = content state in
    ( {
        state with
        nodes =
          List.rev_append
            (List.map
               (fun node -> { node with body = subst node.body })
               state.nodes)
            outer;
      },
      subst content )

  let normalize ~roots ~contents nodes =
    let nodes_by_id =
      Int_map.of_seq
        (Seq.map (fun node -> node.id, node) (List.to_seq nodes))
    in
    let refs =
      Int_map.map (fun { body; _ } -> Term.refs body) nodes_by_id
    in
    let targets id = Term.local_ids (Int_map.find id refs) in
    let partition key =
      let count, _, classes =
        List.fold_left
          (fun (count, previous, classes) (key, id) ->
            match previous with
            | Some (previous_key, class_) when previous_key = key ->
                count, previous, Int_map.add id class_ classes
            | Some _ | None ->
                count + 1, Some (key, id), Int_map.add id id classes)
          (0, None, Int_map.empty)
          (List.sort compare
             (List.map (fun node -> key node, node.id) nodes))
      in
      count, classes
    in
    let n = List.length nodes in
    let refine key (count, classes) =
      if count = n then count, classes
      else partition (fun node -> Int_map.find node.id classes, key node)
    in
    let shape { body; _ } =
      Term.subst
        (function Local _ -> Some 0 | Member _ | Free _ -> None)
        body
    in
    let rec loop ((_, classes) as p) =
      let class_of id = Int_map.find id classes in
      let ((_, classes') as p') =
        refine (fun { id; _ } -> List.map class_of (targets id)) p
      in
      if Int_map.equal Int.equal classes' classes then classes
      else loop p'
    in
    let classes =
      partition (fun { name; _ } -> name) |> refine shape |> loop
    in
    let repr id = Int_map.find id classes in
    let content_refs = List.concat_map Term.refs contents in
    let order =
      let rec loop seen acc = function
        | [], [] -> List.rev acc
        | [], back -> loop seen acc (List.rev back, [])
        | id :: front, back ->
            let id = repr id in
            if Int_set.mem id seen then loop seen acc (front, back)
            else
              loop (Int_set.add id seen) (id :: acc)
                (front, List.rev_append (targets id) back)
      in
      loop Int_set.empty [] (roots @ Term.local_ids content_refs, [])
    in
    let free_names =
      content_refs
      @ List.concat_map (fun id -> Int_map.find id refs) order
      |> List.filter_map (function
        | Term.Free name -> Some name
        | Local _ | Member _ -> None)
      |> String_set.of_list
    in
    let _, names =
      List.fold_left
        (fun (taken, names) id ->
          let name = (Int_map.find id nodes_by_id).name in
          let rec fresh candidate n =
            if String_set.mem candidate taken then
              fresh (name ^ "_" ^ string_of_int n) (n + 1)
            else candidate
          in
          let chosen = fresh name 2 in
          String_set.add chosen taken, Int_map.add id chosen names)
        (free_names, Int_map.empty)
        order
    in
    let name_of id = Int_map.find (repr id) names in
    ( name_of,
      List.map
        (fun id ->
          ( name_of id,
            Term.to_json name_of (Int_map.find id nodes_by_id).body ))
        order )
end

let non_recursive schema =
  let state, content = Definition.parse Definition.empty schema in
  let name_of, definitions =
    Definition.normalize ~roots:[] ~contents:[ content ] state.nodes
  in
  match definitions, Term.to_json name_of content with
  | [], content -> content
  | defs, `Assoc fields -> `Assoc (("$defs", `Assoc defs) :: fields)
  | _, other -> other

type group = {
  definitions : (string * Jsonkit_jsonschema_classify.t) list;
  member_names : (string * string) list;
}

let recursive_group ~path members =
  let state, members =
    List.fold_left_map
      (fun state (name, schema) ->
        let state, body = Definition.parse state schema in
        state, (name, body))
      Definition.empty members
  in
  let members =
    List.mapi
      (fun i (name, body) ->
        { Definition.id = state.next_id + i; name; body })
      members
  in
  let resolve =
    Term.subst (function
      | Member { path = member_path; name }
        when String.equal member_path path ->
          List.find_map
            (fun (member : Definition.t) ->
              if member.name = name then Some member.id else None)
            members
      | Local _ | Member _ | Free _ -> None)
  in
  let name_of, definitions =
    Definition.normalize
      ~roots:(List.map (fun (member : Definition.t) -> member.id) members)
      ~contents:[]
      (List.map
         (fun (node : Definition.t) ->
           { node with body = resolve node.body })
         (state.nodes @ members))
  in
  {
    definitions;
    member_names =
      List.map
        (fun (member : Definition.t) -> member.name, name_of member.id)
        members;
  }

let member name group : Jsonkit_jsonschema_classify.t =
  `Assoc
    [
      "$defs", `Assoc group.definitions;
      "$ref", `String (defs_prefix ^ List.assoc name group.member_names);
    ]

let bundle ~definitions schema =
  let state, schema =
    Definition.enter_scope Definition.empty definitions (fun state ->
        Definition.parse state schema)
  in
  let name_of, definitions =
    Definition.normalize
      ~roots:
        (List.sort compare
           (List.map (fun (node : Definition.t) -> node.id) state.nodes))
      ~contents:[ schema ] state.nodes
  in
  definitions, Term.to_json name_of schema
