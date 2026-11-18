(* Naming [Array] or [List] in the Melange runtime would pull their stdlib
   implementations into every bundle. *)

let array_to_list (a : 'a array) =
  let rec loop i acc =
    if i < 0 then acc else loop (i - 1) (Js.Array.unsafe_get a i :: acc)
  in
  loop (Js.Array.length a - 1) []

let list_to_array (li : 'a list) =
  let a = [||] in
  let rec loop = function
    | [] -> a
    | x :: xs ->
        ignore (Js.Array.push ~value:x a);
        loop xs
  in
  loop li

let list_rev (li : 'a list) =
  let rec loop acc = function
    | [] -> acc
    | x :: xs -> loop (x :: acc) xs
  in
  loop [] li
