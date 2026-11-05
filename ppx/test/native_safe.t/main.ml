type reading = { sensor : string; samples : int } [@@deriving json]
type as_float = { value : float } [@@deriving json]
type as_int = { value : int } [@@deriving json]

let show_error f =
  try f () with
  | Jsonkit.Of_json_error e ->
      print_endline (Jsonkit.of_json_error_to_string e)
  | Jsonkit.Of_string_error msg -> print_endline ("parse error: " ^ msg)

let () =
  let data = Sys.argv.(1) in
  match Sys.argv.(2) with
  | "parse" ->
      show_error (fun () ->
          print_endline (Jsonkit.to_string (Jsonkit.of_string data)))
  | "classify" ->
      show_error (fun () ->
          match Jsonkit.classify (Jsonkit.of_string data) with
          | `Int i -> Printf.printf "Int %d\n" i
          | `Intlit s -> Printf.printf "Intlit %s\n" s
          | `Float f -> Printf.printf "Float %g\n" f
          | `String s -> Printf.printf "String %s\n" s
          | `List l -> Printf.printf "List of %d\n" (List.length l)
          | _ -> print_endline "other")
  | "reading" ->
      show_error (fun () ->
          let r = reading_of_json (Jsonkit.of_string data) in
          Printf.printf "%s has %d samples\n" r.sensor r.samples)
  | "as_float" ->
      show_error (fun () ->
          let r = as_float_of_json (Jsonkit.of_string data) in
          Printf.printf "%g\n" r.value)
  | "as_int" ->
      show_error (fun () ->
          let r = as_int_of_json (Jsonkit.of_string data) in
          Printf.printf "%d\n" r.value)
  | mode -> failwith ("unknown mode " ^ mode)
