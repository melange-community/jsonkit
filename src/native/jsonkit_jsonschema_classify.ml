type t =
  [ `Null
  | `String of string
  | `Float of float
  | `Int of int
  | `Bool of bool
  | `List of t list
  | `Assoc of (string * t) list ]

(* A schema value is standard JSON, so it has no [`Intlit]: an integer literal
   that does not fit a native int becomes an [`Int] when it does fit after all,
   and a [`Float] otherwise. The yojson syntax extensions are mapped by
   [Jsonkit_json_classify], which this goes through so the rule lives in one
   place. (On Melange the same pair converts to and from [Js.Json.t] — see
   ../jsonkit_jsonschema_classify.ml.) *)
let rec classify : Yojson.Safe.t -> t =
 fun json ->
  match Jsonkit_json_classify.classify json with
  | `Intlit s -> (
      match int_of_string_opt s with
      | Some i -> `Int i
      | None -> `Float (float_of_string s))
  | `List l -> `List (List.map classify l)
  | `Assoc fields ->
      `Assoc (List.map (fun (key, v) -> key, classify v) fields)
  | (`Null | `String _ | `Float _ | `Int _ | `Bool _) as value -> value

let declassify : t -> Yojson.Safe.t =
 fun value -> (value :> Yojson.Safe.t)
