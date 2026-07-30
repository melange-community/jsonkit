  $ alias run='../native/ppx_deriving_json_native_test.exe -impl - | ocamlformat - --impl'

  $ cat <<"EOF" | run
  > type user = int [@@deriving json]
  > EOF
  type user = int [@@deriving json]
  
  include struct
    let _ = fun (_ : user) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec user_of_json = (fun x -> int_of_json x : Yojson.Basic.t -> user)
    let _ = user_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec user_to_json = (fun x -> int_to_json x : user -> Yojson.Basic.t)
    let _ = user_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type floaty = float [@@deriving json]
  > EOF
  type floaty = float [@@deriving json]
  
  include struct
    let _ = fun (_ : floaty) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec floaty_of_json =
      (fun x -> float_of_json x : Yojson.Basic.t -> floaty)
  
    let _ = floaty_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec floaty_to_json =
      (fun x -> float_to_json x : floaty -> Yojson.Basic.t)
  
    let _ = floaty_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type 'a param = 'a [@@deriving json]
  > EOF
  type 'a param = 'a [@@deriving json]
  
  include struct
    let _ = fun (_ : 'a param) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec param_of_json a_of_json =
      (fun x -> a_of_json x : Yojson.Basic.t -> 'a param)
  
    let _ = param_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec param_to_json a_to_json =
      (fun x -> a_to_json x : 'a param -> Yojson.Basic.t)
  
    let _ = param_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type opt = string option [@@deriving json]
  > EOF
  type opt = string option [@@deriving json]
  
  include struct
    let _ = fun (_ : opt) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec opt_of_json =
      (fun x -> (option_of_json string_of_json) x : Yojson.Basic.t -> opt)
  
    let _ = opt_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec opt_to_json =
      (fun x -> (option_to_json string_to_json) x : opt -> Yojson.Basic.t)
  
    let _ = opt_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type res = (int, string) result [@@deriving json]
  > EOF
  type res = (int, string) result [@@deriving json]
  
  include struct
    let _ = fun (_ : res) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec res_of_json =
      (fun x -> (result_of_json int_of_json string_of_json) x
        : Yojson.Basic.t -> res)
  
    let _ = res_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec res_to_json =
      (fun x -> (result_to_json int_to_json string_to_json) x
        : res -> Yojson.Basic.t)
  
    let _ = res_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type tuple = int * string [@@deriving json]
  > EOF
  type tuple = int * string [@@deriving json]
  
  include struct
    let _ = fun (_ : tuple) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec tuple_of_json =
      (fun x ->
         match x with
         | `List [ x_0; x_1 ] -> int_of_json x_0, string_of_json x_1
         | _ ->
             Jsonkit.of_json_error ~json:x
               "expected a JSON array of length 2"
        : Yojson.Basic.t -> tuple)
  
    let _ = tuple_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec tuple_to_json =
      (fun x ->
         match x with
         | x_0, x_1 -> `List [ int_to_json x_0; string_to_json x_1 ]
        : tuple -> Yojson.Basic.t)
  
    let _ = tuple_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type record = { name : string; age : int } [@@deriving json]
  > EOF
  type record = { name : string; age : int } [@@deriving json]
  
  include struct
    let _ = fun (_ : record) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_name = ref Stdlib.Option.None in
             let x_age = ref Stdlib.Option.None in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "name" ->
                       x_name := Stdlib.Option.Some (string_of_json v)
                   | "age" -> x_age := Stdlib.Option.Some (int_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               name =
                 (match Stdlib.( ! ) x_name with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"name\"");
               age =
                 (match Stdlib.( ! ) x_age with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"age\"");
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> record)
  
    let _ = record_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_to_json =
      (fun x ->
         match x with
         | { name = x_name; age = x_age } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ = ("age", int_to_json x_age) :: bnds__001_ in
                let bnds__001_ =
                  ("name", string_to_json x_name) :: bnds__001_
                in
                bnds__001_)
        : record -> Yojson.Basic.t)
  
    let _ = record_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type record_aliased = { name : string; [@json.key "my_name"] age : int; [@json.key "my_age"] [@json.default 100] } [@@deriving json]
  > EOF
  type record_aliased = {
    name : string; [@json.key "my_name"]
    age : int; [@json.key "my_age"] [@json.default 100]
  }
  [@@deriving json]
  
  include struct
    let _ = fun (_ : record_aliased) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_aliased_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_name = ref Stdlib.Option.None in
             let x_age = ref (Stdlib.Option.Some 100) in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "my_name" ->
                       x_name := Stdlib.Option.Some (string_of_json v)
                   | "my_age" -> x_age := Stdlib.Option.Some (int_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               name =
                 (match Stdlib.( ! ) x_name with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x
                       "expected field \"my_name\"");
               age =
                 (match Stdlib.( ! ) x_age with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None -> 100);
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> record_aliased)
  
    let _ = record_aliased_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_aliased_to_json =
      (fun x ->
         match x with
         | { name = x_name; age = x_age } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ =
                  ("my_age", int_to_json x_age) :: bnds__001_
                in
                let bnds__001_ =
                  ("my_name", string_to_json x_name) :: bnds__001_
                in
                bnds__001_)
        : record_aliased -> Yojson.Basic.t)
  
    let _ = record_aliased_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type record_opt = { k : int option; [@json.option] } [@@deriving json]
  > EOF
  type record_opt = { k : int option [@json.option] } [@@deriving json]
  
  include struct
    let _ = fun (_ : record_opt) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_opt_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_k = ref (Stdlib.Option.Some Stdlib.Option.None) in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "k" ->
                       x_k :=
                         Stdlib.Option.Some ((option_of_json int_of_json) v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               k =
                 (match Stdlib.( ! ) x_k with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None -> Stdlib.Option.None);
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> record_opt)
  
    let _ = record_opt_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_opt_to_json =
      (fun x ->
         match x with
         | { k = x_k } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ =
                  ("k", (option_to_json int_to_json) x_k) :: bnds__001_
                in
                bnds__001_)
        : record_opt -> Yojson.Basic.t)
  
    let _ = record_opt_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type sum = A | B of int | C of { name : string } [@@deriving json]
  > EOF
  type sum = A | B of int | C of { name : string } [@@deriving json]
  
  include struct
    let _ = fun (_ : sum) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec sum_of_json =
      (fun x ->
         match x with
         | `List (`String "A" :: []) -> A
         | `List [ `String "B"; x_0 ] -> B (int_of_json x_0)
         | `List [ `String "C"; `Assoc fs ] ->
             let x_name = ref Stdlib.Option.None in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "name" ->
                       x_name := Stdlib.Option.Some (string_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             C
               {
                 name =
                   (match Stdlib.( ! ) x_name with
                   | Stdlib.Option.Some v -> v
                   | Stdlib.Option.None ->
                       Jsonkit.of_json_error ~json:x
                         "expected field \"name\"");
               }
         | _ ->
             Jsonkit.of_json_error ~json:x
               "expected [\"A\"] or [\"B\", _] or [\"C\", { _ }]"
        : Yojson.Basic.t -> sum)
  
    let _ = sum_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec sum_to_json =
      (fun x ->
         match x with
         | A -> `List [ `String "A" ]
         | B x_0 -> `List [ `String "B"; int_to_json x_0 ]
         | C { name = x_name } ->
             `List
               [
                 `String "C";
                 `Assoc
                   (let bnds__001_ = [] in
                    let bnds__001_ =
                      ("name", string_to_json x_name) :: bnds__001_
                    in
                    bnds__001_);
               ]
        : sum -> Yojson.Basic.t)
  
    let _ = sum_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type sum2 = S2 of int * string [@@deriving json]
  > EOF
  type sum2 = S2 of int * string [@@deriving json]
  
  include struct
    let _ = fun (_ : sum2) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec sum2_of_json =
      (fun x ->
         match x with
         | `List [ `String "S2"; x_0; x_1 ] ->
             S2 (int_of_json x_0, string_of_json x_1)
         | _ -> Jsonkit.of_json_error ~json:x "expected [\"S2\", _, _]"
        : Yojson.Basic.t -> sum2)
  
    let _ = sum2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec sum2_to_json =
      (fun x ->
         match x with
         | S2 (x_0, x_1) ->
             `List [ `String "S2"; int_to_json x_0; string_to_json x_1 ]
        : sum2 -> Yojson.Basic.t)
  
    let _ = sum2_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type other = [ `C ] [@@deriving json] type poly = [ `A | `B of int | other ] [@@deriving json]
  > EOF
  type other = [ `C ] [@@deriving json]
  
  include struct
    let _ = fun (_ : other) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec other_of_json =
      (fun x ->
         match x with
         | `List (`String "C" :: []) -> `C
         | x ->
             Jsonkit.of_json_unexpected_variant ~json:x "expected [\"C\"]"
        : Yojson.Basic.t -> other)
  
    let _ = other_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec other_to_json =
      (fun x -> match x with `C -> `List [ `String "C" ]
        : other -> Yojson.Basic.t)
  
    let _ = other_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  
  type poly = [ `A | `B of int | other ] [@@deriving json]
  
  include struct
    let _ = fun (_ : poly) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_of_json =
      (fun x ->
         match x with
         | `List (`String "A" :: []) -> `A
         | `List [ `String "B"; x_0 ] -> `B (int_of_json x_0)
         | x -> (
             match other_of_json x with
             | x -> (x :> [ `A | `B of int | other ])
             | exception
                 Jsonkit.Of_json_error (Jsonkit.Unexpected_variant _) ->
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"A\"] or [\"B\", _]")
        : Yojson.Basic.t -> poly)
  
    let _ = poly_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_to_json =
      (fun x ->
         match x with
         | `A -> `List [ `String "A" ]
         | `B x_0 -> `List [ `String "B"; int_to_json x_0 ]
         | #other as x -> other_to_json x
        : poly -> Yojson.Basic.t)
  
    let _ = poly_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type poly2 = [ `P2 of int * string ] [@@deriving json]
  > EOF
  type poly2 = [ `P2 of int * string ] [@@deriving json]
  
  include struct
    let _ = fun (_ : poly2) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly2_of_json =
      (fun x ->
         match x with
         | `List [ `String "P2"; x_0; x_1 ] ->
             `P2 (int_of_json x_0, string_of_json x_1)
         | x ->
             Jsonkit.of_json_unexpected_variant ~json:x
               "expected [\"P2\", _, _]"
        : Yojson.Basic.t -> poly2)
  
    let _ = poly2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly2_to_json =
      (fun x ->
         match x with
         | `P2 (x_0, x_1) ->
             `List [ `String "P2"; int_to_json x_0; string_to_json x_1 ]
        : poly2 -> Yojson.Basic.t)
  
    let _ = poly2_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type 'a c = [ `C of 'a ] [@@deriving json]
  > EOF
  type 'a c = [ `C of 'a ] [@@deriving json]
  
  include struct
    let _ = fun (_ : 'a c) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec c_of_json a_of_json =
      (fun x ->
         match x with
         | `List [ `String "C"; x_0 ] -> `C (a_of_json x_0)
         | x ->
             Jsonkit.of_json_unexpected_variant ~json:x
               "expected [\"C\", _]"
        : Yojson.Basic.t -> 'a c)
  
    let _ = c_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec c_to_json a_to_json =
      (fun x ->
         match x with `C x_0 -> `List [ `String "C"; a_to_json x_0 ]
        : 'a c -> Yojson.Basic.t)
  
    let _ = c_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type recur = A | Fix of recur [@@deriving json]
  > EOF
  type recur = A | Fix of recur [@@deriving json]
  
  include struct
    let _ = fun (_ : recur) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec recur_of_json =
      (fun x ->
         match x with
         | `List (`String "A" :: []) -> A
         | `List [ `String "Fix"; x_0 ] -> Fix (recur_of_json x_0)
         | _ ->
             Jsonkit.of_json_error ~json:x
               "expected [\"A\"] or [\"Fix\", _]"
        : Yojson.Basic.t -> recur)
  
    let _ = recur_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec recur_to_json =
      (fun x ->
         match x with
         | A -> `List [ `String "A" ]
         | Fix x_0 -> `List [ `String "Fix"; recur_to_json x_0 ]
        : recur -> Yojson.Basic.t)
  
    let _ = recur_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type polyrecur = [ `A | `Fix of polyrecur ] [@@deriving json]
  > EOF
  type polyrecur = [ `A | `Fix of polyrecur ] [@@deriving json]
  
  include struct
    let _ = fun (_ : polyrecur) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec polyrecur_of_json =
      (fun x ->
         match x with
         | `List (`String "A" :: []) -> `A
         | `List [ `String "Fix"; x_0 ] -> `Fix (polyrecur_of_json x_0)
         | x ->
             Jsonkit.of_json_unexpected_variant ~json:x
               "expected [\"A\"] or [\"Fix\", _]"
        : Yojson.Basic.t -> polyrecur)
  
    let _ = polyrecur_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec polyrecur_to_json =
      (fun x ->
         match x with
         | `A -> `List [ `String "A" ]
         | `Fix x_0 -> `List [ `String "Fix"; polyrecur_to_json x_0 ]
        : polyrecur -> Yojson.Basic.t)
  
    let _ = polyrecur_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type evar = A | B [@json.name "b_aliased"] [@@deriving json]
  > EOF
  type evar = A | B [@json.name "b_aliased"] [@@deriving json]
  
  include struct
    let _ = fun (_ : evar) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec evar_of_json =
      (fun x ->
         match x with
         | `List (`String "A" :: []) -> A
         | `List (`String "b_aliased" :: []) -> B
         | _ ->
             Jsonkit.of_json_error ~json:x
               "expected [\"A\"] or [\"b_aliased\"]"
        : Yojson.Basic.t -> evar)
  
    let _ = evar_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec evar_to_json =
      (fun x ->
         match x with
         | A -> `List [ `String "A" ]
         | B -> `List [ `String "b_aliased" ]
        : evar -> Yojson.Basic.t)
  
    let _ = evar_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type epoly = [ `a [@json.name "A_aliased"] | `b ] [@@deriving json]
  > EOF
  type epoly = [ `a [@json.name "A_aliased"] | `b ] [@@deriving json]
  
  include struct
    let _ = fun (_ : epoly) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec epoly_of_json =
      (fun x ->
         match x with
         | `List (`String "A_aliased" :: []) -> `a
         | `List (`String "b" :: []) -> `b
         | x ->
             Jsonkit.of_json_unexpected_variant ~json:x
               "expected [\"A_aliased\"] or [\"b\"]"
        : Yojson.Basic.t -> epoly)
  
    let _ = epoly_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec epoly_to_json =
      (fun x ->
         match x with
         | `a -> `List [ `String "A_aliased" ]
         | `b -> `List [ `String "b" ]
        : epoly -> Yojson.Basic.t)
  
    let _ = epoly_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type ('a, 'b) p2 = A of 'a | B of 'b [@@deriving json]
  > EOF
  type ('a, 'b) p2 = A of 'a | B of 'b [@@deriving json]
  
  include struct
    let _ = fun (_ : ('a, 'b) p2) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec p2_of_json a_of_json b_of_json =
      (fun x ->
         match x with
         | `List [ `String "A"; x_0 ] -> A (a_of_json x_0)
         | `List [ `String "B"; x_0 ] -> B (b_of_json x_0)
         | _ ->
             Jsonkit.of_json_error ~json:x
               "expected [\"A\", _] or [\"B\", _]"
        : Yojson.Basic.t -> ('a, 'b) p2)
  
    let _ = p2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec p2_to_json a_to_json b_to_json =
      (fun x ->
         match x with
         | A x_0 -> `List [ `String "A"; a_to_json x_0 ]
         | B x_0 -> `List [ `String "B"; b_to_json x_0 ]
        : ('a, 'b) p2 -> Yojson.Basic.t)
  
    let _ = p2_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type allow_extra_fields = {a: int} [@@deriving json] [@@json.allow_extra_fields]
  > EOF
  type allow_extra_fields = { a : int }
  [@@deriving json] [@@json.allow_extra_fields]
  
  include struct
    let _ = fun (_ : allow_extra_fields) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec allow_extra_fields_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_a = ref Stdlib.Option.None in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "a" -> x_a := Stdlib.Option.Some (int_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               a =
                 (match Stdlib.( ! ) x_a with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"a\"");
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> allow_extra_fields)
  
    let _ = allow_extra_fields_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec allow_extra_fields_to_json =
      (fun x ->
         match x with
         | { a = x_a } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ = ("a", int_to_json x_a) :: bnds__001_ in
                bnds__001_)
        : allow_extra_fields -> Yojson.Basic.t)
  
    let _ = allow_extra_fields_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type allow_extra_fields2 = A of {a: int} [@json.allow_extra_fields] [@@deriving json]
  > EOF
  type allow_extra_fields2 = A of { a : int } [@json.allow_extra_fields]
  [@@deriving json]
  
  include struct
    let _ = fun (_ : allow_extra_fields2) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec allow_extra_fields2_of_json =
      (fun x ->
         match x with
         | `List [ `String "A"; `Assoc fs ] ->
             let x_a = ref Stdlib.Option.None in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "a" -> x_a := Stdlib.Option.Some (int_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             A
               {
                 a =
                   (match Stdlib.( ! ) x_a with
                   | Stdlib.Option.Some v -> v
                   | Stdlib.Option.None ->
                       Jsonkit.of_json_error ~json:x "expected field \"a\"");
               }
         | _ -> Jsonkit.of_json_error ~json:x "expected [\"A\", { _ }]"
        : Yojson.Basic.t -> allow_extra_fields2)
  
    let _ = allow_extra_fields2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec allow_extra_fields2_to_json =
      (fun x ->
         match x with
         | A { a = x_a } ->
             `List
               [
                 `String "A";
                 `Assoc
                   (let bnds__001_ = [] in
                    let bnds__001_ = ("a", int_to_json x_a) :: bnds__001_ in
                    bnds__001_);
               ]
        : allow_extra_fields2 -> Yojson.Basic.t)
  
    let _ = allow_extra_fields2_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

  $ cat <<"EOF" | run
  > type compact_variant = A | B of int [@@deriving json] [@@json.compact_variants]
  > EOF
  type compact_variant = A | B of int
  [@@deriving json] [@@json.compact_variants]
  
  include struct
    let _ = fun (_ : compact_variant) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec compact_variant_of_json =
      (fun x ->
         match x with
         | `String "A" | `List (`String "A" :: []) -> A
         | `List [ `String "B"; x_0 ] -> B (int_of_json x_0)
         | _ -> Jsonkit.of_json_error ~json:x "expected \"A\" or [\"B\", _]"
        : Yojson.Basic.t -> compact_variant)
  
    let _ = compact_variant_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec compact_variant_to_json =
      (fun x ->
         match x with
         | A -> `String "A"
         | B x_0 -> `List [ `String "B"; int_to_json x_0 ]
        : compact_variant -> Yojson.Basic.t)
  
    let _ = compact_variant_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]








  $ cat <<"EOF" | run
  > type drop_default_option = { a: int; b_opt: int option; [@option] [@json.drop_default] } [@@deriving json]
  > EOF
  type drop_default_option = {
    a : int;
    b_opt : int option; [@option] [@json.drop_default]
  }
  [@@deriving json]
  
  include struct
    let _ = fun (_ : drop_default_option) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_option_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_a = ref Stdlib.Option.None in
             let x_b_opt = ref (Stdlib.Option.Some Stdlib.Option.None) in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "a" -> x_a := Stdlib.Option.Some (int_of_json v)
                   | "b_opt" ->
                       x_b_opt :=
                         Stdlib.Option.Some ((option_of_json int_of_json) v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               a =
                 (match Stdlib.( ! ) x_a with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"a\"");
               b_opt =
                 (match Stdlib.( ! ) x_b_opt with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None -> Stdlib.Option.None);
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> drop_default_option)
  
    let _ = drop_default_option_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_option_to_json =
      (fun x ->
         match x with
         | { a = x_a; b_opt = x_b_opt } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ =
                  match x_b_opt with
                  | Stdlib.Option.None -> bnds__001_
                  | Stdlib.Option.Some _ ->
                      ("b_opt", (option_to_json int_to_json) x_b_opt)
                      :: bnds__001_
                in
                let bnds__001_ = ("a", int_to_json x_a) :: bnds__001_ in
                bnds__001_)
        : drop_default_option -> Yojson.Basic.t)
  
    let _ = drop_default_option_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  $ cat <<"EOF" | run
  > type drop_default = { a: int; b: int; [@default 1] [@json.drop_default (fun a b -> if compare a b = 0 then true else false)] } [@@deriving json]
  > EOF
  type drop_default = {
    a : int;
    b : int;
        [@default 1]
        [@json.drop_default
          fun a b -> if compare a b = 0 then true else false]
  }
  [@@deriving json]
  
  include struct
    let _ = fun (_ : drop_default) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_a = ref Stdlib.Option.None in
             let x_b = ref (Stdlib.Option.Some 1) in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "a" -> x_a := Stdlib.Option.Some (int_of_json v)
                   | "b" -> x_b := Stdlib.Option.Some (int_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               a =
                 (match Stdlib.( ! ) x_a with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"a\"");
               b =
                 (match Stdlib.( ! ) x_b with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None -> 1);
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> drop_default)
  
    let _ = drop_default_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_to_json =
      (fun x ->
         match x with
         | { a = x_a; b = x_b } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ =
                  if
                    (fun a b -> if compare a b = 0 then true else false)
                      x_b 1
                  then bnds__001_
                  else ("b", int_to_json x_b) :: bnds__001_
                in
                let bnds__001_ = ("a", int_to_json x_a) :: bnds__001_ in
                bnds__001_)
        : drop_default -> Yojson.Basic.t)
  
    let _ = drop_default_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  $ cat <<"EOF" | run
  > type drop_default_default_eq = { a: int; b: int; [@default 1] [@json.drop_default] } [@@deriving json]
  > EOF
  type drop_default_default_eq = {
    a : int;
    b : int; [@default 1] [@json.drop_default]
  }
  [@@deriving json]
  
  include struct
    let _ = fun (_ : drop_default_default_eq) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_default_eq_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_a = ref Stdlib.Option.None in
             let x_b = ref (Stdlib.Option.Some 1) in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "a" -> x_a := Stdlib.Option.Some (int_of_json v)
                   | "b" -> x_b := Stdlib.Option.Some (int_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               a =
                 (match Stdlib.( ! ) x_a with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"a\"");
               b =
                 (match Stdlib.( ! ) x_b with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None -> 1);
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> drop_default_default_eq)
  
    let _ = drop_default_default_eq_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_default_eq_to_json =
      (fun x ->
         match x with
         | { a = x_a; b = x_b } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ =
                  if equal_int x_b 1 then bnds__001_
                  else ("b", int_to_json x_b) :: bnds__001_
                in
                let bnds__001_ = ("a", int_to_json x_a) :: bnds__001_ in
                bnds__001_)
        : drop_default_default_eq -> Yojson.Basic.t)
  
    let _ = drop_default_default_eq_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  $ cat <<"EOF" | run
  > type drop_default_if_json_equal = { a: int; b: int; [@default 1] [@json.drop_default_if_json_equal] } [@@deriving json]
  > EOF
  type drop_default_if_json_equal = {
    a : int;
    b : int; [@default 1] [@json.drop_default_if_json_equal]
  }
  [@@deriving json]
  
  include struct
    let _ = fun (_ : drop_default_if_json_equal) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_if_json_equal_of_json =
      (fun x ->
         match x with
         | `Assoc fs ->
             let x_a = ref Stdlib.Option.None in
             let x_b = ref (Stdlib.Option.Some 1) in
             let rec iter = function
               | [] -> ()
               | (n', v) :: fs ->
                   (match n' with
                   | "a" -> x_a := Stdlib.Option.Some (int_of_json v)
                   | "b" -> x_b := Stdlib.Option.Some (int_of_json v)
                   | _ -> ());
                   iter fs
             in
             iter fs;
             {
               a =
                 (match Stdlib.( ! ) x_a with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"a\"");
               b =
                 (match Stdlib.( ! ) x_b with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None -> 1);
             }
         | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
        : Yojson.Basic.t -> drop_default_if_json_equal)
  
    let _ = drop_default_if_json_equal_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_if_json_equal_to_json =
      (fun x ->
         match x with
         | { a = x_a; b = x_b } ->
             `Assoc
               (let bnds__001_ = [] in
                let bnds__001_ =
                  let json = int_to_json x_b in
                  if Jsonkit.equal json (int_to_json 1) then bnds__001_
                  else ("b", json) :: bnds__001_
                in
                let bnds__001_ = ("a", int_to_json x_a) :: bnds__001_ in
                bnds__001_)
        : drop_default_if_json_equal -> Yojson.Basic.t)
  
    let _ = drop_default_if_json_equal_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Test for polyvariant without own cases (only inherits) - should not produce unused variable warning for `tag`:

  $ cat <<"EOF" | run
  > type one = [ `C ] [@@deriving json]
  > type other = [ `C ] [@@deriving json]
  > type poly = [ one | other ] [@@deriving json]
  > EOF
  type one = [ `C ] [@@deriving json]
  
  include struct
    let _ = fun (_ : one) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec one_of_json =
      (fun x ->
         match x with
         | `List (`String "C" :: []) -> `C
         | x ->
             Jsonkit.of_json_unexpected_variant ~json:x "expected [\"C\"]"
        : Yojson.Basic.t -> one)
  
    let _ = one_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec one_to_json =
      (fun x -> match x with `C -> `List [ `String "C" ]
        : one -> Yojson.Basic.t)
  
    let _ = one_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  
  type other = [ `C ] [@@deriving json]
  
  include struct
    let _ = fun (_ : other) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec other_of_json =
      (fun x ->
         match x with
         | `List (`String "C" :: []) -> `C
         | x ->
             Jsonkit.of_json_unexpected_variant ~json:x "expected [\"C\"]"
        : Yojson.Basic.t -> other)
  
    let _ = other_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec other_to_json =
      (fun x -> match x with `C -> `List [ `String "C" ]
        : other -> Yojson.Basic.t)
  
    let _ = other_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  
  type poly = [ one | other ] [@@deriving json]
  
  include struct
    let _ = fun (_ : poly) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_of_json =
      (fun x ->
         match x with
         | x -> (
             match other_of_json x with
             | x -> (x :> [ one | other ])
             | exception
                 Jsonkit.Of_json_error (Jsonkit.Unexpected_variant _) -> (
                 match one_of_json x with
                 | x -> (x :> [ one | other ])
                 | exception
                     Jsonkit.Of_json_error (Jsonkit.Unexpected_variant _) ->
                     Jsonkit.of_json_unexpected_variant ~json:x "expected ")
             )
        : Yojson.Basic.t -> poly)
  
    let _ = poly_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_to_json =
      (fun x ->
         match x with
         | #one as x -> one_to_json x
         | #other as x -> other_to_json x
        : poly -> Yojson.Basic.t)
  
    let _ = poly_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
