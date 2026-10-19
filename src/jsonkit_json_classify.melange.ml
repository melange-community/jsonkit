module J = Js.Json

type t = J.t

let dict_to_list_without_undefined dict =
  let keys = Js.Dict.keys dict in
  let l = Array.length keys in
  let xs = ref [] in
  for i = l - 1 downto 0 do
    let key = Array.unsafe_get keys i in
    let value = Js.Dict.unsafeGet dict key in
    if not ((Obj.magic value : _ Js.Undefined.t) == Js.undefined) then
      xs := (key, value) :: !xs
  done;
  !xs

let classify :
    t ->
    [ `Null
    | `String of string
    | `Float of float
    | `Int of int
    | `Bool of bool
    | `List of t list
    | `Assoc of (string * t) list ] =
 fun json ->
  if (Obj.magic json : 'a Js.null) == Js.null then `Null
  else
    match Js.typeof json with
    | "string" -> `String (Obj.magic json : string)
    | "number" ->
        let v = (Obj.magic json : float) in
        if Js.Float.isFinite v && Js.Math.floor_float v == v then
          `Int (Obj.magic v : int)
        else `Float v
    | "boolean" -> `Bool (Obj.magic json : bool)
    | "object" ->
        if Js.Array.isArray json then
          let xs = Array.to_list (Obj.magic json : t array) in
          `List xs
        else
          `Assoc
            (dict_to_list_without_undefined
               (Obj.magic json : t Js.Dict.t))
    | typ -> failwith ("unknown JSON value type: " ^ typ)

let declassify :
    [ `Null
    | `String of string
    | `Float of float
    | `Int of int
    | `Bool of bool
    | `List of t list
    | `Assoc of (string * t) list ] ->
    t = function
  | `Null -> J.null
  | `String str -> J.string str
  | `Float f -> J.number f
  | `Int i -> J.number (Js.Int.toFloat i)
  | `Bool b -> J.boolean b
  | `List li -> J.array (Array.of_list li)
  | `Assoc assoc -> J.object_ (Js.Dict.fromList assoc)
