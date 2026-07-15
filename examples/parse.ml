(* Parsing a JSON string using Jsonkit.parseOrRaise *)

let arrayOfInts str =
  let json = Jsonkit.of_string str in
  Jsonkit.Of_json.(array int json)

(* prints `[3, 2, 1]` *)
let _ = Js.log (arrayOfInts "[1, 2, 3]" |> Js.Array.reverseInPlace)
