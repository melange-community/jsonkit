(* Runtime checks on the code generated for recursive type groups. *)

[@@@warning "-37-69"]

open Jsonkit.Primitives

let check condition message = if not condition then failwith message

(* The helper holding the group's definitions is bound inside the values'
   own binding and never reaches the user's scope. *)
let ppx_defs_hidden = 41

type hidden = Hidden_end | Hidden of hidden_tail

and hidden_tail = Hidden_tail_end | Hidden_tail of hidden
[@@deriving jsonschema]

let () =
  check (ppx_defs_hidden + 1 = 42) "generated helper escaped its scope"

(* Each value evaluates every body of its group exactly once. *)
let probe_calls = ref 0

type 'a probe = 'a

let probe_jsonschema schema =
  incr probe_calls;
  schema

type probed = { value : int probe; tail : probed_tail option }
and probed_tail = Probed_tail of probed option [@@deriving jsonschema]

let () =
  check (!probe_calls = 2)
    (Printf.sprintf "recursive schema body was evaluated %d times, not 2"
       !probe_calls)

(* Definitions collected from external recursive types used by any member
   reach every value of the group. *)
type 'a box = { inner : 'a; self : 'a box option } [@@deriving jsonschema]

type boxed = Boxed of boxed_tail | Boxed_end
and boxed_tail = Boxed_tail of boxed box [@@deriving jsonschema]

let definition_names : Jsonkit.Jsonschema.t -> string list = function
  | `Assoc fields -> (
      match List.assoc_opt "$defs" fields with
      | Some (`Assoc defs) -> List.map fst defs
      | _ -> [])
  | _ -> []

let () =
  List.iter
    (fun (name, schema) ->
      check
        (List.mem "box" (definition_names schema))
        (name ^ "_jsonschema lost the $defs of box"))
    [ "boxed", boxed_jsonschema; "boxed_tail", boxed_tail_jsonschema ]
