open Jsonkit.Primitives

let print fmt = Printf.ksprintf print_endline fmt

module To_json_string = struct
  type ('a, 'b) t = A of 'a | B of 'b
  [@@deriving to_json, to_json_string]

  let test () =
    let to_json_string = to_json_string int_to_json bool_to_json in
    print "** To_json_string **";
    print "A 42 -> %s" (to_json_string (A 42));
    print "B false -> %s" (to_json_string (B false))
end

module Of_json_string = struct
  type ('a, 'b) t = A of 'a | B of 'b
  [@@deriving of_json, of_json_string]

  let test () =
    let of_json_string = of_json_string int_of_json bool_of_json in
    print "** Of_json_string **";
    print {|["A", 42] = A 42 -> %b|} (of_json_string {|["A", 42]|} = A 42);
    print {|["B", false] = B false -> %b|}
      (of_json_string {|["B", false]|} = B false)
end

module Json_string = struct
  type ('a, 'b) t = A of 'a | B of 'b [@@deriving json, json_string]

  let test () =
    print "** Json_string **";
    let to_json_string = to_json_string int_to_json bool_to_json in
    print "A 42 -> %s" (to_json_string (A 42));
    print "B false -> %s" (to_json_string (B false));
    let of_json_string = of_json_string int_of_json bool_of_json in
    print {|["A", 42] = A 42 -> %b|} (of_json_string {|["A", 42]|} = A 42);
    print {|["B", false] = B false -> %b|}
      (of_json_string {|["B", false]|} = B false)
end

let test () =
  To_json_string.test ();
  Of_json_string.test ();
  Json_string.test ()
