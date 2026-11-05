type t = Yojson.Safe.t

(* [`Tuple] and [`Variant] are yojson's own syntax extensions, not JSON, and
   [Yojson.Safe.from_string] does accept them. They are reported as the JSON
   shape they stand for, so a classified value only ever has the eight cases
   the Melange backend also has. *)
let classify :
    t ->
    [ `Null
    | `String of string
    | `Float of float
    | `Int of int
    | `Intlit of string
    | `Bool of bool
    | `List of t list
    | `Assoc of (string * t) list ] = function
  | `Tuple elements -> `List elements
  | `Variant (name, None) -> `String name
  | `Variant (name, Some payload) -> `List [ `String name; payload ]
  | ( `Null | `String _ | `Float _ | `Int _ | `Intlit _ | `Bool _
    | `List _ | `Assoc _ ) as json ->
      json

let declassify :
    [ `Null
    | `String of string
    | `Float of float
    | `Int of int
    | `Intlit of string
    | `Bool of bool
    | `List of t list
    | `Assoc of (string * t) list ] ->
    t =
 fun x -> (x :> t)
