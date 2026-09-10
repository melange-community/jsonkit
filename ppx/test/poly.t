We can alias poly variants:
  $ echo '
  > type t = [`A | `B] [@@deriving json]
  > type u = t [@@deriving json]
  > let () = print_endline (Jsonkit.to_string (u_to_json `A))
  > let () = assert (u_of_json (Jsonkit.of_string {|["B"]|}) = `B)
  > ' | ./run.sh
  === ppx output:native ===
  type t = [ `A  | `B ][@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           match x with
           | `List ((`String "A")::[]) -> `A
           | `List ((`String "B")::[]) -> `B
           | x ->
               Jsonkit.of_json_unexpected_variant ~json:x
                 "expected [\"A\"] or [\"B\"]" : Yojson.Basic.t -> t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with | `A -> `List [`String "A"] | `B -> `List [`String "B"] : 
        t -> Yojson.Basic.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type u = t[@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json = (fun x -> of_json x : Yojson.Basic.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json = (fun x -> to_json x : u -> Yojson.Basic.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json `A))
  let () = assert ((u_of_json (Jsonkit.of_string {|["B"]|})) = `B)
  === ppx output:browser ===
  type t = [ `A  | `B ][@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "A"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `A)
                    else
                      if Stdlib.(=) (Obj.magic tag : string) "B"
                      then
                        (if Stdlib.(<>) len 1
                         then
                           Jsonkit.of_json_error ~json:x
                             "expected a JSON array of length 1"
                         else `B)
                      else
                        Jsonkit.of_json_unexpected_variant ~json:x
                          "expected [\"A\"] or [\"B\"]")
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | `A -> (Obj.magic [|(Obj.magic "A" : Js.Json.t)|] : Js.Json.t)
           | `B -> (Obj.magic [|(Obj.magic "B" : Js.Json.t)|] : Js.Json.t) : 
        t -> Js.Json.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type u = t[@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json = (fun x -> of_json x : Js.Json.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json = (fun x -> to_json x : u -> Js.Json.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json `A))
  let () = assert ((u_of_json (Jsonkit.of_string {|["B"]|})) = `B)
  === stdout:native ===
  ["A"]
  === stdout:js ===
  ["A"]

We can extend aliased polyvariants:
  $ echo '
  > type t = [`A | `B] [@@deriving json]
  > type u = [t | `C] [@@deriving json]
  > let () = print_endline (Jsonkit.to_string (u_to_json `A))
  > let () = print_endline (Jsonkit.to_string (u_to_json `C))
  > let () = assert (u_of_json (Jsonkit.of_string {|["B"]|}) = `B)
  > let () = assert (u_of_json (Jsonkit.of_string {|["C"]|}) = `C)
  > ' | ./run.sh
  === ppx output:native ===
  type t = [ `A  | `B ][@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           match x with
           | `List ((`String "A")::[]) -> `A
           | `List ((`String "B")::[]) -> `B
           | x ->
               Jsonkit.of_json_unexpected_variant ~json:x
                 "expected [\"A\"] or [\"B\"]" : Yojson.Basic.t -> t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with | `A -> `List [`String "A"] | `B -> `List [`String "B"] : 
        t -> Yojson.Basic.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type u = [ | t | `C ][@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json =
        (fun x ->
           match x with
           | `List ((`String "C")::[]) -> `C
           | x ->
               (match of_json x with
                | x -> (x :> [ | t | `C ])
                | exception Jsonkit.Of_json_error (Jsonkit.Unexpected_variant
                    _) ->
                    Jsonkit.of_json_unexpected_variant ~json:x
                      "expected [\"C\"]") : Yojson.Basic.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json =
        (fun x ->
           match x with | #t as x -> to_json x | `C -> `List [`String "C"] : 
        u -> Yojson.Basic.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json `A))
  let () = print_endline (Jsonkit.to_string (u_to_json `C))
  let () = assert ((u_of_json (Jsonkit.of_string {|["B"]|})) = `B)
  let () = assert ((u_of_json (Jsonkit.of_string {|["C"]|})) = `C)
  === ppx output:browser ===
  type t = [ `A  | `B ][@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "A"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `A)
                    else
                      if Stdlib.(=) (Obj.magic tag : string) "B"
                      then
                        (if Stdlib.(<>) len 1
                         then
                           Jsonkit.of_json_error ~json:x
                             "expected a JSON array of length 1"
                         else `B)
                      else
                        Jsonkit.of_json_unexpected_variant ~json:x
                          "expected [\"A\"] or [\"B\"]")
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | `A -> (Obj.magic [|(Obj.magic "A" : Js.Json.t)|] : Js.Json.t)
           | `B -> (Obj.magic [|(Obj.magic "B" : Js.Json.t)|] : Js.Json.t) : 
        t -> Js.Json.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type u = [ | t | `C ][@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "C"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `C)
                    else
                      (match of_json x with
                       | e -> (e :> [ | t | `C ])
                       | exception Jsonkit.Of_json_error
                           (Jsonkit.Unexpected_variant _) ->
                           Jsonkit.of_json_unexpected_variant ~json:x
                             "expected [\"C\"]"))
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json =
        (fun x ->
           match x with
           | #t as x -> to_json x
           | `C -> (Obj.magic [|(Obj.magic "C" : Js.Json.t)|] : Js.Json.t) : 
        u -> Js.Json.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json `A))
  let () = print_endline (Jsonkit.to_string (u_to_json `C))
  let () = assert ((u_of_json (Jsonkit.of_string {|["B"]|})) = `B)
  let () = assert ((u_of_json (Jsonkit.of_string {|["C"]|})) = `C)
  === stdout:native ===
  ["A"]
  ["C"]
  === stdout:js ===
  ["A"]
  ["C"]

We can extend poly variants which are placed behind signatures:
  $ echo '
  > module P : sig
  >   type t = [`A | `B] [@@deriving json]
  > end = struct
  >   type t = [`A | `B] [@@deriving json]
  > end
  > type u = [P.t | `C] [@@deriving json]
  > let () = print_endline (Jsonkit.to_string (u_to_json `A))
  > let () = print_endline (Jsonkit.to_string (u_to_json `C))
  > let () = assert (u_of_json (Jsonkit.of_string {|["B"]|}) = `B)
  > let () = assert (u_of_json (Jsonkit.of_string {|["C"]|}) = `C)
  > ' | ./run.sh
  === ppx output:native ===
  module P :
    sig
      type t = [ `A  | `B ][@@deriving json]
      include
        sig
          [@@@ocaml.warning "-32"]
          val of_json : Yojson.Basic.t -> t
          val to_json : t -> Yojson.Basic.t
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end =
    struct
      type t = [ `A  | `B ][@@deriving json]
      include
        struct
          let _ = fun (_ : t) -> ()
          [@@@ocaml.warning "-39-11-27"]
          let rec of_json =
            (fun x ->
               match x with
               | `List ((`String "A")::[]) -> `A
               | `List ((`String "B")::[]) -> `B
               | x ->
                   Jsonkit.of_json_unexpected_variant ~json:x
                     "expected [\"A\"] or [\"B\"]" : Yojson.Basic.t -> t)
          let _ = of_json
          [@@@ocaml.warning "-39-11-27"]
          let rec to_json =
            (fun x ->
               match x with
               | `A -> `List [`String "A"]
               | `B -> `List [`String "B"] : t -> Yojson.Basic.t)
          let _ = to_json
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end 
  type u = [ | P.t | `C ][@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json =
        (fun x ->
           match x with
           | `List ((`String "C")::[]) -> `C
           | x ->
               (match P.of_json x with
                | x -> (x :> [ | P.t | `C ])
                | exception Jsonkit.Of_json_error (Jsonkit.Unexpected_variant
                    _) ->
                    Jsonkit.of_json_unexpected_variant ~json:x
                      "expected [\"C\"]") : Yojson.Basic.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json =
        (fun x ->
           match x with | #P.t as x -> P.to_json x | `C -> `List [`String "C"] : 
        u -> Yojson.Basic.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json `A))
  let () = print_endline (Jsonkit.to_string (u_to_json `C))
  let () = assert ((u_of_json (Jsonkit.of_string {|["B"]|})) = `B)
  let () = assert ((u_of_json (Jsonkit.of_string {|["C"]|})) = `C)
  === ppx output:browser ===
  module P :
    sig
      type t = [ `A  | `B ][@@deriving json]
      include
        sig
          [@@@ocaml.warning "-32"]
          val of_json : Js.Json.t -> t
          val to_json : t -> Js.Json.t
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end =
    struct
      type t = [ `A  | `B ][@@deriving json]
      include
        struct
          let _ = fun (_ : t) -> ()
          [@@@ocaml.warning "-39-11-27"]
          let rec of_json =
            (fun x ->
               if Js.Array.isArray x
               then
                 let array = (Obj.magic x : Js.Json.t array) in
                 let len = Js.Array.length array in
                 (if Stdlib.(>) len 0
                  then
                    let tag = Js.Array.unsafe_get array 0 in
                    (if Stdlib.(=) (Js.typeof tag) "string"
                     then
                       (if Stdlib.(=) (Obj.magic tag : string) "A"
                        then
                          (if Stdlib.(<>) len 1
                           then
                             Jsonkit.of_json_error ~json:x
                               "expected a JSON array of length 1"
                           else `A)
                        else
                          if Stdlib.(=) (Obj.magic tag : string) "B"
                          then
                            (if Stdlib.(<>) len 1
                             then
                               Jsonkit.of_json_error ~json:x
                                 "expected a JSON array of length 1"
                             else `B)
                          else
                            Jsonkit.of_json_unexpected_variant ~json:x
                              "expected [\"A\"] or [\"B\"]")
                     else
                       Jsonkit.of_json_error ~json:x
                         "expected a non empty JSON array with element being a string")
                  else
                    Jsonkit.of_json_error ~json:x
                      "expected a non empty JSON array")
               else
                 Jsonkit.of_json_error ~json:x
                   "expected a non empty JSON array" : Js.Json.t -> t)
          let _ = of_json
          [@@@ocaml.warning "-39-11-27"]
          let rec to_json =
            (fun x ->
               match x with
               | `A -> (Obj.magic [|(Obj.magic "A" : Js.Json.t)|] : Js.Json.t)
               | `B -> (Obj.magic [|(Obj.magic "B" : Js.Json.t)|] : Js.Json.t) : 
            t -> Js.Json.t)
          let _ = to_json
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end 
  type u = [ | P.t | `C ][@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "C"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `C)
                    else
                      (match P.of_json x with
                       | e -> (e :> [ | P.t | `C ])
                       | exception Jsonkit.Of_json_error
                           (Jsonkit.Unexpected_variant _) ->
                           Jsonkit.of_json_unexpected_variant ~json:x
                             "expected [\"C\"]"))
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json =
        (fun x ->
           match x with
           | #P.t as x -> P.to_json x
           | `C -> (Obj.magic [|(Obj.magic "C" : Js.Json.t)|] : Js.Json.t) : 
        u -> Js.Json.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json `A))
  let () = print_endline (Jsonkit.to_string (u_to_json `C))
  let () = assert ((u_of_json (Jsonkit.of_string {|["B"]|})) = `B)
  let () = assert ((u_of_json (Jsonkit.of_string {|["C"]|})) = `C)
  === stdout:native ===
  ["A"]
  ["C"]
  === stdout:js ===
  ["A"]
  ["C"]

Inherited variants are decoded after the type's own tags, whatever their
position in the definition. Here [t] has a catch-all, so trying it first would
swallow ["B"] as `Other instead of `B (the native backend already ordered it
this way):
  $ echo '
  > type t = [`A | `Other of Jsonkit.unknown_variant_case [@json.catch_all]] [@@deriving json]
  > type u = [t | `B] [@@deriving json]
  > let () =
  >   match u_of_json (Jsonkit.of_string {|["B"]|}) with
  >   | `A -> print_endline "A"
  >   | `B -> print_endline "B"
  >   | `Other { Jsonkit.tag; _ } -> print_endline ("Other " ^ tag)
  > ' | ./run.sh
  === ppx output:native ===
  type t = [ `A  | `Other of Jsonkit.unknown_variant_case [@json.catch_all ]]
  [@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           match x with
           | `List ((`String "A")::[]) -> `A
           | x ->
               (match x with
                | `String _ | `List ((`String _)::_) as v ->
                    let (tag, payload) =
                      match v with
                      | `String s -> (s, Stdlib.Option.None)
                      | `List ((`String s)::payload) ->
                          (s, (Stdlib.Option.Some payload))
                      | _ -> assert false in
                    `Other ({ tag; payload } : Jsonkit.unknown_variant_case)
                | _ ->
                    Jsonkit.of_json_unexpected_variant ~json:x
                      "expected [\"A\"] or [\"Other\", _]") : Yojson.Basic.t ->
                                                                t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | `A -> `List [`String "A"]
           | `Other x_0 ->
               (match x_0.payload with
                | Stdlib.Option.None -> `String (x_0.tag)
                | Stdlib.Option.Some xs -> `List ((`String (x_0.tag)) :: xs)) : 
        t -> Yojson.Basic.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type u = [ | t | `B ][@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json =
        (fun x ->
           match x with
           | `List ((`String "B")::[]) -> `B
           | x ->
               (match of_json x with
                | x -> (x :> [ | t | `B ])
                | exception Jsonkit.Of_json_error (Jsonkit.Unexpected_variant
                    _) ->
                    Jsonkit.of_json_unexpected_variant ~json:x
                      "expected [\"B\"]") : Yojson.Basic.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json =
        (fun x ->
           match x with | #t as x -> to_json x | `B -> `List [`String "B"] : 
        u -> Yojson.Basic.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    match u_of_json (Jsonkit.of_string {|["B"]|}) with
    | `A -> print_endline "A"
    | `B -> print_endline "B"
    | `Other { Jsonkit.tag = tag;_} -> print_endline ("Other " ^ tag)
  === ppx output:browser ===
  type t = [ `A  | `Other of Jsonkit.unknown_variant_case [@json.catch_all ]]
  [@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "A"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `A)
                    else
                      `Other
                        ((let payload =
                            if Stdlib.(=) len 0
                            then Stdlib.Option.None
                            else
                              if Stdlib.(=) len 1
                              then Stdlib.Option.Some []
                              else
                                (let rest =
                                   ((Stdlib.Array.sub array 1
                                       (Stdlib.(-) len 1))
                                      |> Stdlib.Array.to_list)
                                     |>
                                     (Stdlib.List.map (fun j -> Obj.magic j)) in
                                 Stdlib.Option.Some rest) in
                          ({ tag = (Obj.magic tag : string); payload } : 
                            Jsonkit.unknown_variant_case))))
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | `A -> (Obj.magic [|(Obj.magic "A" : Js.Json.t)|] : Js.Json.t)
           | `Other x_0 ->
               (match x_0.payload with
                | Stdlib.Option.None ->
                    (Obj.magic (x_0.tag : string) : Js.Json.t)
                | Stdlib.Option.Some xs ->
                    let head = (Obj.magic (x_0.tag : string) : Js.Json.t) in
                    let rest =
                      Stdlib.List.map (fun (j : Jsonkit.t) -> Obj.magic j) xs in
                    (Obj.magic
                       (Stdlib.Array.of_list (head :: rest) : Js.Json.t array) : 
                      Js.Json.t)) : t -> Js.Json.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type u = [ | t | `B ][@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "B"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `B)
                    else
                      (match of_json x with
                       | e -> (e :> [ | t | `B ])
                       | exception Jsonkit.Of_json_error
                           (Jsonkit.Unexpected_variant _) ->
                           Jsonkit.of_json_unexpected_variant ~json:x
                             "expected [\"B\"]"))
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json =
        (fun x ->
           match x with
           | #t as x -> to_json x
           | `B -> (Obj.magic [|(Obj.magic "B" : Js.Json.t)|] : Js.Json.t) : 
        u -> Js.Json.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    match u_of_json (Jsonkit.of_string {|["B"]|}) with
    | `A -> print_endline "A"
    | `B -> print_endline "B"
    | `Other { Jsonkit.tag = tag;_} -> print_endline ("Other " ^ tag)
  === stdout:native ===
  B
  === stdout:js ===
  B

A [@json.catch_all] row on the type itself is tried after the inherited
decoders, whatever its position in the definition. Otherwise it would swallow
every tag the inherited type knows how to decode (["Alpha"] must be `Alpha, not
`Other), on both backends:
  $ echo '
  > type poly_known = [ `Alpha | `Beta ] [@@deriving json]
  > type poly_own_catch_all = [ poly_known | `Other of Jsonkit.unknown_variant_case [@json.catch_all] ] [@@deriving json]
  > let () =
  >   let show = function
  >     | `Alpha -> "Alpha"
  >     | `Beta -> "Beta"
  >     | `Other { Jsonkit.tag; _ } -> "Other " ^ tag
  >   in
  >   print_endline (show (poly_own_catch_all_of_json (Jsonkit.of_string {|["Alpha"]|})));
  >   print_endline (show (poly_own_catch_all_of_json (Jsonkit.of_string {|["Zzz"]|})))
  > ' | ./run.sh
  === ppx output:native ===
  type poly_known = [ `Alpha  | `Beta ][@@deriving json]
  include
    struct
      let _ = fun (_ : poly_known) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_of_json =
        (fun x ->
           match x with
           | `List ((`String "Alpha")::[]) -> `Alpha
           | `List ((`String "Beta")::[]) -> `Beta
           | x ->
               Jsonkit.of_json_unexpected_variant ~json:x
                 "expected [\"Alpha\"] or [\"Beta\"]" : Yojson.Basic.t ->
                                                          poly_known)
      let _ = poly_known_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_to_json =
        (fun x ->
           match x with
           | `Alpha -> `List [`String "Alpha"]
           | `Beta -> `List [`String "Beta"] : poly_known -> Yojson.Basic.t)
      let _ = poly_known_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type poly_own_catch_all =
    [ | poly_known | `Other of Jsonkit.unknown_variant_case [@json.catch_all ]]
  [@@deriving json]
  include
    struct
      let _ = fun (_ : poly_own_catch_all) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_own_catch_all_of_json =
        (fun x ->
           match x with
           | x ->
               (match poly_known_of_json x with
                | x ->
                    (x :> [ | poly_known
                          | `Other of Jsonkit.unknown_variant_case
                              [@json.catch_all ]])
                | exception Jsonkit.Of_json_error (Jsonkit.Unexpected_variant
                    _) ->
                    (match x with
                     | `String _ | `List ((`String _)::_) as v ->
                         let (tag, payload) =
                           match v with
                           | `String s -> (s, Stdlib.Option.None)
                           | `List ((`String s)::payload) ->
                               (s, (Stdlib.Option.Some payload))
                           | _ -> assert false in
                         `Other
                           ({ tag; payload } : Jsonkit.unknown_variant_case)
                     | _ ->
                         Jsonkit.of_json_unexpected_variant ~json:x
                           "expected [\"Other\", _]")) : Yojson.Basic.t ->
                                                           poly_own_catch_all)
      let _ = poly_own_catch_all_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_own_catch_all_to_json =
        (fun x ->
           match x with
           | #poly_known as x -> poly_known_to_json x
           | `Other x_0 ->
               (match x_0.payload with
                | Stdlib.Option.None -> `String (x_0.tag)
                | Stdlib.Option.Some xs -> `List ((`String (x_0.tag)) :: xs)) : 
        poly_own_catch_all -> Yojson.Basic.t)
      let _ = poly_own_catch_all_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    let show =
      function
      | `Alpha -> "Alpha"
      | `Beta -> "Beta"
      | `Other { Jsonkit.tag = tag;_} -> "Other " ^ tag in
    print_endline
      (show (poly_own_catch_all_of_json (Jsonkit.of_string {|["Alpha"]|})));
    print_endline
      (show (poly_own_catch_all_of_json (Jsonkit.of_string {|["Zzz"]|})))
  === ppx output:browser ===
  type poly_known = [ `Alpha  | `Beta ][@@deriving json]
  include
    struct
      let _ = fun (_ : poly_known) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "Alpha"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `Alpha)
                    else
                      if Stdlib.(=) (Obj.magic tag : string) "Beta"
                      then
                        (if Stdlib.(<>) len 1
                         then
                           Jsonkit.of_json_error ~json:x
                             "expected a JSON array of length 1"
                         else `Beta)
                      else
                        Jsonkit.of_json_unexpected_variant ~json:x
                          "expected [\"Alpha\"] or [\"Beta\"]")
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> poly_known)
      let _ = poly_known_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_to_json =
        (fun x ->
           match x with
           | `Alpha ->
               (Obj.magic [|(Obj.magic "Alpha" : Js.Json.t)|] : Js.Json.t)
           | `Beta ->
               (Obj.magic [|(Obj.magic "Beta" : Js.Json.t)|] : Js.Json.t) : 
        poly_known -> Js.Json.t)
      let _ = poly_known_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type poly_own_catch_all =
    [ | poly_known | `Other of Jsonkit.unknown_variant_case [@json.catch_all ]]
  [@@deriving json]
  include
    struct
      let _ = fun (_ : poly_own_catch_all) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_own_catch_all_of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   match poly_known_of_json x with
                   | e ->
                       (e :> [ | poly_known
                             | `Other of Jsonkit.unknown_variant_case
                                 [@json.catch_all ]])
                   | exception Jsonkit.Of_json_error
                       (Jsonkit.Unexpected_variant _) ->
                       `Other
                         (let payload =
                            if Stdlib.(=) len 0
                            then Stdlib.Option.None
                            else
                              if Stdlib.(=) len 1
                              then Stdlib.Option.Some []
                              else
                                (let rest =
                                   ((Stdlib.Array.sub array 1
                                       (Stdlib.(-) len 1))
                                      |> Stdlib.Array.to_list)
                                     |>
                                     (Stdlib.List.map (fun j -> Obj.magic j)) in
                                 Stdlib.Option.Some rest) in
                          ({ tag = (Obj.magic tag : string); payload } : 
                            Jsonkit.unknown_variant_case))
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> poly_own_catch_all)
      let _ = poly_own_catch_all_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_own_catch_all_to_json =
        (fun x ->
           match x with
           | #poly_known as x -> poly_known_to_json x
           | `Other x_0 ->
               (match x_0.payload with
                | Stdlib.Option.None ->
                    (Obj.magic (x_0.tag : string) : Js.Json.t)
                | Stdlib.Option.Some xs ->
                    let head = (Obj.magic (x_0.tag : string) : Js.Json.t) in
                    let rest =
                      Stdlib.List.map (fun (j : Jsonkit.t) -> Obj.magic j) xs in
                    (Obj.magic
                       (Stdlib.Array.of_list (head :: rest) : Js.Json.t array) : 
                      Js.Json.t)) : poly_own_catch_all -> Js.Json.t)
      let _ = poly_own_catch_all_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    let show =
      function
      | `Alpha -> "Alpha"
      | `Beta -> "Beta"
      | `Other { Jsonkit.tag = tag;_} -> "Other " ^ tag in
    print_endline
      (show (poly_own_catch_all_of_json (Jsonkit.of_string {|["Alpha"]|})));
    print_endline
      (show (poly_own_catch_all_of_json (Jsonkit.of_string {|["Zzz"]|})))
  === stdout:native ===
  Alpha
  Other Zzz
  === stdout:js ===
  Alpha
  Other Zzz

The same holds when the [@json.catch_all] row is written before the inherited
type: own tags, then the inherited decoders, then the catch-all, on both
backends:
  $ echo '
  > type poly_known = [ `Alpha | `Beta ] [@@deriving json]
  > type poly_catch_all_inherit_second = [ `Other of Jsonkit.unknown_variant_case [@json.catch_all] | poly_known ] [@@deriving json]
  > let () =
  >   let show = function
  >     | `Alpha -> "Alpha"
  >     | `Beta -> "Beta"
  >     | `Other { Jsonkit.tag; _ } -> "Other " ^ tag
  >   in
  >   print_endline (show (poly_catch_all_inherit_second_of_json (Jsonkit.of_string {|["Alpha"]|})));
  >   print_endline (show (poly_catch_all_inherit_second_of_json (Jsonkit.of_string {|["Zzz"]|})))
  > ' | ./run.sh
  === ppx output:native ===
  type poly_known = [ `Alpha  | `Beta ][@@deriving json]
  include
    struct
      let _ = fun (_ : poly_known) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_of_json =
        (fun x ->
           match x with
           | `List ((`String "Alpha")::[]) -> `Alpha
           | `List ((`String "Beta")::[]) -> `Beta
           | x ->
               Jsonkit.of_json_unexpected_variant ~json:x
                 "expected [\"Alpha\"] or [\"Beta\"]" : Yojson.Basic.t ->
                                                          poly_known)
      let _ = poly_known_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_to_json =
        (fun x ->
           match x with
           | `Alpha -> `List [`String "Alpha"]
           | `Beta -> `List [`String "Beta"] : poly_known -> Yojson.Basic.t)
      let _ = poly_known_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type poly_catch_all_inherit_second =
    [ `Other of Jsonkit.unknown_variant_case [@json.catch_all ] | poly_known]
  [@@deriving json]
  include
    struct
      let _ = fun (_ : poly_catch_all_inherit_second) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_catch_all_inherit_second_of_json =
        (fun x ->
           match x with
           | x ->
               (match poly_known_of_json x with
                | x ->
                    (x :> [
                            `Other of Jsonkit.unknown_variant_case
                              [@json.catch_all ]
                          | poly_known])
                | exception Jsonkit.Of_json_error (Jsonkit.Unexpected_variant
                    _) ->
                    (match x with
                     | `String _ | `List ((`String _)::_) as v ->
                         let (tag, payload) =
                           match v with
                           | `String s -> (s, Stdlib.Option.None)
                           | `List ((`String s)::payload) ->
                               (s, (Stdlib.Option.Some payload))
                           | _ -> assert false in
                         `Other
                           ({ tag; payload } : Jsonkit.unknown_variant_case)
                     | _ ->
                         Jsonkit.of_json_unexpected_variant ~json:x
                           "expected [\"Other\", _]")) : Yojson.Basic.t ->
                                                           poly_catch_all_inherit_second)
      let _ = poly_catch_all_inherit_second_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_catch_all_inherit_second_to_json =
        (fun x ->
           match x with
           | `Other x_0 ->
               (match x_0.payload with
                | Stdlib.Option.None -> `String (x_0.tag)
                | Stdlib.Option.Some xs -> `List ((`String (x_0.tag)) :: xs))
           | #poly_known as x -> poly_known_to_json x : poly_catch_all_inherit_second
                                                          -> Yojson.Basic.t)
      let _ = poly_catch_all_inherit_second_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    let show =
      function
      | `Alpha -> "Alpha"
      | `Beta -> "Beta"
      | `Other { Jsonkit.tag = tag;_} -> "Other " ^ tag in
    print_endline
      (show
         (poly_catch_all_inherit_second_of_json
            (Jsonkit.of_string {|["Alpha"]|})));
    print_endline
      (show
         (poly_catch_all_inherit_second_of_json (Jsonkit.of_string {|["Zzz"]|})))
  === ppx output:browser ===
  type poly_known = [ `Alpha  | `Beta ][@@deriving json]
  include
    struct
      let _ = fun (_ : poly_known) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   (if Stdlib.(=) (Obj.magic tag : string) "Alpha"
                    then
                      (if Stdlib.(<>) len 1
                       then
                         Jsonkit.of_json_error ~json:x
                           "expected a JSON array of length 1"
                       else `Alpha)
                    else
                      if Stdlib.(=) (Obj.magic tag : string) "Beta"
                      then
                        (if Stdlib.(<>) len 1
                         then
                           Jsonkit.of_json_error ~json:x
                             "expected a JSON array of length 1"
                         else `Beta)
                      else
                        Jsonkit.of_json_unexpected_variant ~json:x
                          "expected [\"Alpha\"] or [\"Beta\"]")
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> poly_known)
      let _ = poly_known_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_known_to_json =
        (fun x ->
           match x with
           | `Alpha ->
               (Obj.magic [|(Obj.magic "Alpha" : Js.Json.t)|] : Js.Json.t)
           | `Beta ->
               (Obj.magic [|(Obj.magic "Beta" : Js.Json.t)|] : Js.Json.t) : 
        poly_known -> Js.Json.t)
      let _ = poly_known_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  type poly_catch_all_inherit_second =
    [ `Other of Jsonkit.unknown_variant_case [@json.catch_all ] | poly_known]
  [@@deriving json]
  include
    struct
      let _ = fun (_ : poly_catch_all_inherit_second) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_catch_all_inherit_second_of_json =
        (fun x ->
           if Js.Array.isArray x
           then
             let array = (Obj.magic x : Js.Json.t array) in
             let len = Js.Array.length array in
             (if Stdlib.(>) len 0
              then
                let tag = Js.Array.unsafe_get array 0 in
                (if Stdlib.(=) (Js.typeof tag) "string"
                 then
                   match poly_known_of_json x with
                   | e ->
                       (e :> [
                               `Other of Jsonkit.unknown_variant_case
                                 [@json.catch_all ]
                             | poly_known])
                   | exception Jsonkit.Of_json_error
                       (Jsonkit.Unexpected_variant _) ->
                       `Other
                         (let payload =
                            if Stdlib.(=) len 0
                            then Stdlib.Option.None
                            else
                              if Stdlib.(=) len 1
                              then Stdlib.Option.Some []
                              else
                                (let rest =
                                   ((Stdlib.Array.sub array 1
                                       (Stdlib.(-) len 1))
                                      |> Stdlib.Array.to_list)
                                     |>
                                     (Stdlib.List.map (fun j -> Obj.magic j)) in
                                 Stdlib.Option.Some rest) in
                          ({ tag = (Obj.magic tag : string); payload } : 
                            Jsonkit.unknown_variant_case))
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a string")
              else
                Jsonkit.of_json_error ~json:x "expected a non empty JSON array")
           else Jsonkit.of_json_error ~json:x "expected a non empty JSON array" : 
        Js.Json.t -> poly_catch_all_inherit_second)
      let _ = poly_catch_all_inherit_second_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec poly_catch_all_inherit_second_to_json =
        (fun x ->
           match x with
           | `Other x_0 ->
               (match x_0.payload with
                | Stdlib.Option.None ->
                    (Obj.magic (x_0.tag : string) : Js.Json.t)
                | Stdlib.Option.Some xs ->
                    let head = (Obj.magic (x_0.tag : string) : Js.Json.t) in
                    let rest =
                      Stdlib.List.map (fun (j : Jsonkit.t) -> Obj.magic j) xs in
                    (Obj.magic
                       (Stdlib.Array.of_list (head :: rest) : Js.Json.t array) : 
                      Js.Json.t))
           | #poly_known as x -> poly_known_to_json x : poly_catch_all_inherit_second
                                                          -> Js.Json.t)
      let _ = poly_catch_all_inherit_second_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    let show =
      function
      | `Alpha -> "Alpha"
      | `Beta -> "Beta"
      | `Other { Jsonkit.tag = tag;_} -> "Other " ^ tag in
    print_endline
      (show
         (poly_catch_all_inherit_second_of_json
            (Jsonkit.of_string {|["Alpha"]|})));
    print_endline
      (show
         (poly_catch_all_inherit_second_of_json (Jsonkit.of_string {|["Zzz"]|})))
  === stdout:native ===
  Alpha
  Other Zzz
  === stdout:js ===
  Alpha
  Other Zzz
