type t = Js.Json.t

external string : string -> t = "%identity"
external bool : bool -> t = "%identity"
external int : int -> t = "%identity"

let int64 : int64 -> t = fun v -> Obj.magic (Int64.to_string v)

external float : float -> t = "%identity"

let unit () : t = Obj.magic Js.null

let array v_to_json vs : t =
  let vs : Js.Json.t array = Js.Array.map ~f:v_to_json vs in
  Obj.magic vs

let list v_to_json vs : t =
  let vs = Array.of_list vs in
  array v_to_json vs

let option v_to_json v : t =
  match v with None -> Obj.magic Js.null | Some v -> v_to_json v

let result a_to_json b_to_json v : t =
  match v with
  | Ok x -> Obj.magic [| string "Ok"; a_to_json x |]
  | Error x -> Obj.magic [| string "Error"; b_to_json x |]

let char c = string (String.make 1 c)
let js_date d = string (Js.Date.toJSONUnsafe d)

let js_null v_to_json v =
  match Js.Null.toOption v with
  | None -> Obj.magic Js.null
  | Some v -> v_to_json v

external json_dict : Js.Json.t Js.Dict.t -> Js.Json.t = "%identity"

let js_dict encode d =
  let pairs = Js.Dict.entries d in
  let encodedPairs = Array.map (fun (k, v) -> k, encode v) pairs in
  json_dict (Js.Dict.fromArray encodedPairs)

external json_array : Js.Json.t array -> Js.Json.t = "%identity"

let tuple2 encodeA encodeB (a, b) = json_array [| encodeA a; encodeB b |]

let tuple3 encodeA encodeB encodeC (a, b, c) =
  json_array [| encodeA a; encodeB b; encodeC c |]

let tuple4 encodeA encodeB encodeC encodeD (a, b, c, d) =
  json_array [| encodeA a; encodeB b; encodeC c; encodeD d |]

external string_array : string array -> Js.Json.t = "%identity"
external float_array : float array -> Js.Json.t = "%identity"
external int_array : int array -> Js.Json.t = "%identity"
external bool_array : bool array -> Js.Json.t = "%identity"
