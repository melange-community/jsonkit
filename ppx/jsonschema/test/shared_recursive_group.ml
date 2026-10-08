open Jsonkit.Primitives

[@@@warning "-37-69"]

let ppx_defs_helper_hidden = 41

type helper_hidden = Helper_end | Helper_hidden of helper_hidden_tail

and helper_hidden_tail =
  | Helper_hidden_tail_end
  | Helper_hidden_tail of helper_hidden
[@@deriving jsonschema]

let _ =
  Helper_hidden Helper_hidden_tail_end, Helper_hidden_tail Helper_end

let probe_calls = ref 0

type 'a probe = 'a

let probe_jsonschema schema =
  incr probe_calls;
  schema

type probed = { value : int probe; tail : probed_tail option }
and probed_tail = Probed_tail of probed option [@@deriving jsonschema]

let () =
  let sample = { value = 1; tail = Some (Probed_tail None) } in
  ignore (sample.value, sample.tail);
  if ppx_defs_helper_hidden + 1 <> 42 then
    failwith "generated helper escaped its scope";
  if !probe_calls <> 1 then
    failwith "recursive schema body was evaluated more than once"

let field name : Jsonkit.Jsonschema.t -> Jsonkit.Jsonschema.t option =
  function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let def_names schema =
  match field "$defs" schema with
  | Some (`Assoc defs) -> List.map fst defs
  | _ -> []

type 'a wrap = Wrap of 'a wrap option | Value of 'a
[@@deriving jsonschema]

type wrapped_a = Wrapped_a of wrapped_b | Wrapped_stop
and wrapped_b = Wrapped_b of wrapped_a wrap [@@deriving jsonschema]

let () =
  ignore (Wrap None, Value (), Wrapped_a (Wrapped_b (Value Wrapped_stop)));
  if not (List.mem "wrap" (def_names wrapped_a_jsonschema)) then
    failwith "wrapped_a_jsonschema lost the $defs of wrap";
  if not (List.mem "wrap" (def_names wrapped_b_jsonschema)) then
    failwith "wrapped_b_jsonschema lost the $defs of wrap"

type described_a = { b : described_b option }
[@@jsonschema.description "A"]

and described_b = { a : described_a option }
[@@jsonschema.description "B"] [@@deriving jsonschema]

type described_pair = { x : described_a; y : described_b }
[@@deriving jsonschema]

let () =
  let schema = Jsonkit.Jsonschema.make described_pair_jsonschema in
  if
    List.sort compare (def_names schema)
    <> [ "described_a"; "described_b" ]
  then failwith "described group was not merged into one set of $defs";
  match field "$defs" schema with
  | Some defs ->
      List.iter
        (fun name ->
          match Option.bind (field name defs) (field "description") with
          | Some (`String _) -> ()
          | _ -> failwith (name ^ " lost its description"))
        [ "described_a"; "described_b" ]
  | None -> assert false

module Same_ref_a = struct
  type t = { foo : t option; u : u }
  and u = { x : int } [@@deriving jsonschema]
end

module Same_ref_b = struct
  type t = { foo : t option; u : u }
  and u = { x : string } [@@deriving jsonschema]
end

type same_ref = { a : Same_ref_a.t; b : Same_ref_b.t }
[@@deriving jsonschema]

let () =
  let schema = Jsonkit.Jsonschema.make same_ref_jsonschema in
  let ref_of name =
    match
      Option.bind (field "properties" schema) (fun properties ->
          Option.bind (field name properties) (field "$ref"))
    with
    | Some (`String ref) -> ref
    | _ -> failwith ("no $ref for " ^ name)
  in
  if String.equal (ref_of "a") (ref_of "b") then
    failwith "same_ref merged two t definitions with different u"

(* A group member and an embedded recursive schema share the name [t]: the
   embedded definition must be renamed, and its refs to the caller's [t]
   must still reach the group's own definition. *)
module Collide = struct
  module Chain = struct
    type 'a t = { next : 'a t option; v : 'a } [@@deriving jsonschema]
  end

  type t = Leaf | Node of t Chain.t [@@deriving jsonschema]
end

let () =
  let schema = Collide.t_jsonschema in
  let names = def_names schema in
  if List.length names <> List.length (List.sort_uniq compare names) then
    failwith "Collide.t has duplicate $defs keys";
  let defs =
    match field "$defs" schema with
    | Some defs -> defs
    | None -> assert false
  in
  let target ref_field =
    match ref_field with
    | Some (`String ref) ->
        let prefix = "#/$defs/" in
        String.sub ref (String.length prefix)
          (String.length ref - String.length prefix)
    | _ -> failwith "expected a $ref"
  in
  let root = target (field "$ref" schema) in
  let chain =
    List.find
      (fun name ->
        match Option.bind (field name defs) (field "properties") with
        | Some properties -> Option.is_some (field "v" properties)
        | None -> false)
      names
  in
  let v =
    Option.bind (field chain defs) (field "properties")
    |> Fun.flip Option.bind (field "v")
  in
  if String.equal chain root then
    failwith "Collide.t: Chain.t took the group's own name";
  if not (String.equal (target (Option.bind v (field "$ref"))) root) then
    failwith "Collide.t: Chain.t's v no longer points at the group's t"

(* A type argument refers to the caller's [u], and the parametric type it is
   passed to embeds a different definition also named [u]: the caller's ref
   must keep pointing at the caller's [u]. *)
module Capture = struct
  module Inner = struct
    type u = { next : u option; inner : int } [@@deriving jsonschema]
    type 'a holder = { x : 'a; y : u } [@@deriving jsonschema]
  end

  type u = Leaf | Node of u Inner.holder [@@deriving jsonschema]
end

let () =
  let schema = Jsonkit.Jsonschema.make Capture.u_jsonschema in
  let defs =
    match field "$defs" schema with
    | Some defs -> defs
    | None -> assert false
  in
  let target = function
    | Some (`String ref) -> String.sub ref 8 (String.length ref - 8)
    | _ -> failwith "expected a $ref"
  in
  let root = target (field "$ref" schema) in
  (* The variant's [Node] payload is the holder object; its [x] must point
     back at the variant itself. *)
  let rec find_x : Jsonkit.Jsonschema.t -> Jsonkit.Jsonschema.t option =
    function
    | `Assoc fields -> (
        match List.assoc_opt "properties" fields with
        | Some (`Assoc props) when List.mem_assoc "x" props ->
            List.assoc_opt "x" props
        | _ -> List.find_map (fun (_, v) -> find_x v) fields)
    | `List values -> List.find_map find_x values
    | _ -> None
  in
  match Option.bind (field root defs) find_x with
  | Some x ->
      if not (String.equal (target (field "$ref" x)) root) then
        failwith "Capture: the caller's ref was captured by Inner.u"
  | None -> failwith "Capture: no holder found under the root definition"
