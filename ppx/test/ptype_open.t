We can use the `Ptyp_open` AST node:
  $ echo '
  > module X = struct
  >  type x = (int * int) [@@deriving json]
  > end
  > type u = X.(x) [@@deriving json]
  > let () = print_endline (Jsonkit.to_string (u_to_json (1, 2)))
  > let () = assert (u_of_json (Jsonkit.of_string {|[1, 2]|}) = (1, 2))
  > ' | ./run.sh
  === ppx output:native ===
  module X =
    struct
      type x = (int * int)[@@deriving json]
      include
        struct
          let _ = fun (_ : x) -> ()
          [@@@ocaml.warning "-39-11-27"]
          let rec x_of_json =
            (fun x ->
               match x with
               | `List (x_0::x_1::[]) -> ((int_of_json x_0), (int_of_json x_1))
               | _ ->
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2" : Yojson.Basic.t -> x)
          let _ = x_of_json
          [@@@ocaml.warning "-39-11-27"]
          let rec x_to_json =
            (fun x ->
               match x with
               | (x_0, x_1) -> `List [int_to_json x_0; int_to_json x_1] : 
            x -> Yojson.Basic.t)
          let _ = x_to_json
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end
  type u = X.(x)[@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json = (fun x -> X.x_of_json x : Yojson.Basic.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json = (fun x -> X.x_to_json x : u -> Yojson.Basic.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json (1, 2)))
  let () = assert ((u_of_json (Jsonkit.of_string {|[1, 2]|})) = (1, 2))
  === ppx output:browser ===
  module X =
    struct
      type x = (int * int)[@@deriving json]
      include
        struct
          let _ = fun (_ : x) -> ()
          [@@@ocaml.warning "-39-11-27"]
          let rec x_of_json =
            (fun x ->
               if
                 Stdlib.(&&) (Js.Array.isArray x)
                   (Stdlib.(=)
                      (Js.Array.length (Obj.magic x : Js.Json.t array)) 2)
               then
                 let es = (Obj.magic x : Js.Json.t array) in
                 ((int_of_json (Js.Array.unsafe_get es 0)),
                   (int_of_json (Js.Array.unsafe_get es 1)))
               else
                 Jsonkit.of_json_error ~json:x
                   "expected a JSON array of length 2" : Js.Json.t -> x)
          let _ = x_of_json
          [@@@ocaml.warning "-39-11-27"]
          let rec x_to_json =
            (fun x ->
               match x with
               | (x_0, x_1) ->
                   (Obj.magic [|(int_to_json x_0);(int_to_json x_1)|] : 
                   Js.Json.t) : x -> Js.Json.t)
          let _ = x_to_json
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end
  type u = X.(x)[@@deriving json]
  include
    struct
      let _ = fun (_ : u) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec u_of_json = (fun x -> X.x_of_json x : Js.Json.t -> u)
      let _ = u_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec u_to_json = (fun x -> X.x_to_json x : u -> Js.Json.t)
      let _ = u_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () = print_endline (Jsonkit.to_string (u_to_json (1, 2)))
  let () = assert ((u_of_json (Jsonkit.of_string {|[1, 2]|})) = (1, 2))
  === stdout:native ===
  [1,2]
  === stdout:js ===
  [1,2]
