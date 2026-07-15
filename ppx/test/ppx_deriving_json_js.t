  $ alias run='../browser/ppx_deriving_json_js_test.exe -impl - | ocamlformat - --impl'

  $ cat <<"EOF" | run
  > type user = int [@@deriving json]
  > EOF
  type user = int [@@deriving json]
  
  include struct
    let _ = fun (_ : user) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec user_of_json = (fun x -> int_of_json x : Js.Json.t -> user)
    let _ = user_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec user_to_json = (fun x -> int_to_json x : user -> Js.Json.t)
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
      (fun x -> float_of_json x : Js.Json.t -> floaty)
  
    let _ = floaty_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec floaty_to_json =
      (fun x -> float_to_json x : floaty -> Js.Json.t)
  
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
      (fun x -> a_of_json x : Js.Json.t -> 'a param)
  
    let _ = param_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec param_to_json a_to_json =
      (fun x -> a_to_json x : 'a param -> Js.Json.t)
  
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
      (fun x -> (option_of_json string_of_json) x : Js.Json.t -> opt)
  
    let _ = opt_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec opt_to_json =
      (fun x -> (option_to_json string_to_json) x : opt -> Js.Json.t)
  
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
        : Js.Json.t -> res)
  
    let _ = res_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec res_to_json =
      (fun x -> (result_to_json int_to_json string_to_json) x
        : res -> Js.Json.t)
  
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
         if
           Stdlib.( && ) (Js.Array.isArray x)
             (Stdlib.( = )
                (Js.Array.length (Obj.magic x : Js.Json.t array))
                2)
         then
           let es = (Obj.magic x : Js.Json.t array) in
           ( int_of_json (Js.Array.unsafe_get es 0),
             string_of_json (Js.Array.unsafe_get es 1) )
         else
           Jsonkit.of_json_error ~json:x "expected a JSON array of length 2"
        : Js.Json.t -> tuple)
  
    let _ = tuple_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec tuple_to_json =
      (fun x ->
         match x with
         | x_0, x_1 ->
             (Obj.magic [| int_to_json x_0; string_to_json x_1 |]
               : Js.Json.t)
        : tuple -> Js.Json.t)
  
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs =
           (Obj.magic x
             : < name : Js.Json.t Js.undefined
               ; age : Js.Json.t Js.undefined >
               Js.t)
         in
         {
           name =
             (match Js.Undefined.toOption fs##name with
             | Stdlib.Option.Some v -> string_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"name\" to be present");
           age =
             (match Js.Undefined.toOption fs##age with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"age\" to be present");
         }
        : Js.Json.t -> record)
  
    let _ = record_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_to_json =
      (fun x ->
         match x with
         | { name = x_name; age = x_age } ->
             (Obj.magic
                [%mel.obj
                  { name = string_to_json x_name; age = int_to_json x_age }]
               : Js.Json.t)
        : record -> Js.Json.t)
  
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs =
           (Obj.magic x
             : < my_name : Js.Json.t Js.undefined
               ; my_age : Js.Json.t Js.undefined >
               Js.t)
         in
         {
           name =
             (match Js.Undefined.toOption fs##my_name with
             | Stdlib.Option.Some v -> string_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"my_name\" to be present");
           age =
             (match Js.Undefined.toOption fs##my_age with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None -> 100);
         }
        : Js.Json.t -> record_aliased)
  
    let _ = record_aliased_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_aliased_to_json =
      (fun x ->
         match x with
         | { name = x_name; age = x_age } ->
             (Obj.magic
                [%mel.obj
                  {
                    my_name = string_to_json x_name;
                    my_age = int_to_json x_age;
                  }]
               : Js.Json.t)
        : record_aliased -> Js.Json.t)
  
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs = (Obj.magic x : < k : Js.Json.t Js.undefined > Js.t) in
         {
           k =
             (match Js.Undefined.toOption fs##k with
             | Stdlib.Option.Some v -> (option_of_json int_of_json) v
             | Stdlib.Option.None -> Stdlib.Option.None);
         }
        : Js.Json.t -> record_opt)
  
    let _ = record_opt_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec record_opt_to_json =
      (fun x ->
         match x with
         | { k = x_k } ->
             (Obj.magic [%mel.obj { k = (option_to_json int_to_json) x_k }]
               : Js.Json.t)
        : record_opt -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else A
               else if Stdlib.( = ) (Obj.magic tag : string) "B" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else B (int_of_json (Js.Array.unsafe_get array 1))
               else if Stdlib.( = ) (Obj.magic tag : string) "C" then (
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else
                   let fs = Js.Array.unsafe_get array 1 in
                   if
                     Stdlib.not
                       (Stdlib.( && )
                          (Stdlib.( = ) (Js.typeof fs) "object")
                          (Stdlib.( && )
                             (Stdlib.not (Js.Array.isArray fs))
                             (Stdlib.not
                                (Stdlib.( == )
                                   (Obj.magic fs : 'a Js.null)
                                   Js.null))))
                   then
                     Jsonkit.of_json_error ~json:fs "expected a JSON object";
                   let fs =
                     (Obj.magic fs : < name : Js.Json.t Js.undefined > Js.t)
                   in
                   C
                     {
                       name =
                         (match Js.Undefined.toOption fs##name with
                         | Stdlib.Option.Some v -> string_of_json v
                         | Stdlib.Option.None ->
                             Jsonkit.of_json_error ~json:x
                               "expected field \"name\" to be present");
                     })
               else
                 Jsonkit.of_json_error ~json:x
                   "expected [\"C\", { _ }] or [\"B\", _] or [\"A\"]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> sum)
  
    let _ = sum_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec sum_to_json =
      (fun x ->
         match x with
         | A -> (Obj.magic [| (Obj.magic "A" : Js.Json.t) |] : Js.Json.t)
         | B x_0 ->
             (Obj.magic [| (Obj.magic "B" : Js.Json.t); int_to_json x_0 |]
               : Js.Json.t)
         | C { name = x_name } ->
             (Obj.magic
                [|
                  (Obj.magic "C" : Js.Json.t);
                  (Obj.magic [%mel.obj { name = string_to_json x_name }]
                    : Js.Json.t);
                |]
               : Js.Json.t)
        : sum -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "S2" then
                 if Stdlib.( <> ) len 3 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 3"
                 else
                   S2
                     ( int_of_json (Js.Array.unsafe_get array 1),
                       string_of_json (Js.Array.unsafe_get array 2) )
               else Jsonkit.of_json_error ~json:x "expected [\"S2\", _, _]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> sum2)
  
    let _ = sum2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec sum2_to_json =
      (fun x ->
         match x with
         | S2 (x_0, x_1) ->
             (Obj.magic
                [|
                  (Obj.magic "S2" : Js.Json.t);
                  int_to_json x_0;
                  string_to_json x_1;
                |]
               : Js.Json.t)
        : sum2 -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "C" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else `C
               else
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"C\"]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> other)
  
    let _ = other_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec other_to_json =
      (fun x ->
         match x with
         | `C -> (Obj.magic [| (Obj.magic "C" : Js.Json.t) |] : Js.Json.t)
        : other -> Js.Json.t)
  
    let _ = other_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  
  type poly = [ `A | `B of int | other ] [@@deriving json]
  
  include struct
    let _ = fun (_ : poly) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_of_json =
      (fun x ->
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else `A
               else if Stdlib.( = ) (Obj.magic tag : string) "B" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else `B (int_of_json (Js.Array.unsafe_get array 1))
               else
                 match other_of_json x with
                 | e -> (e :> [ `A | `B of int | other ])
                 | exception
                     Jsonkit.Of_json_error (Jsonkit.Unexpected_variant _) ->
                     Jsonkit.of_json_unexpected_variant ~json:x
                       "expected [\"A\"] or [\"B\", _]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> poly)
  
    let _ = poly_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_to_json =
      (fun x ->
         match x with
         | `A -> (Obj.magic [| (Obj.magic "A" : Js.Json.t) |] : Js.Json.t)
         | `B x_0 ->
             (Obj.magic [| (Obj.magic "B" : Js.Json.t); int_to_json x_0 |]
               : Js.Json.t)
         | #other as x -> other_to_json x
        : poly -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "P2" then
                 if Stdlib.( <> ) len 3 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 3"
                 else
                   `P2
                     ( int_of_json (Js.Array.unsafe_get array 1),
                       string_of_json (Js.Array.unsafe_get array 2) )
               else
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"P2\", _, _]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> poly2)
  
    let _ = poly2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly2_to_json =
      (fun x ->
         match x with
         | `P2 (x_0, x_1) ->
             (Obj.magic
                [|
                  (Obj.magic "P2" : Js.Json.t);
                  int_to_json x_0;
                  string_to_json x_1;
                |]
               : Js.Json.t)
        : poly2 -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "C" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else `C (a_of_json (Js.Array.unsafe_get array 1))
               else
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"C\", _]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> 'a c)
  
    let _ = c_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec c_to_json a_to_json =
      (fun x ->
         match x with
         | `C x_0 ->
             (Obj.magic [| (Obj.magic "C" : Js.Json.t); a_to_json x_0 |]
               : Js.Json.t)
        : 'a c -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else A
               else if Stdlib.( = ) (Obj.magic tag : string) "Fix" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else Fix (recur_of_json (Js.Array.unsafe_get array 1))
               else
                 Jsonkit.of_json_error ~json:x
                   "expected [\"Fix\", _] or [\"A\"]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> recur)
  
    let _ = recur_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec recur_to_json =
      (fun x ->
         match x with
         | A -> (Obj.magic [| (Obj.magic "A" : Js.Json.t) |] : Js.Json.t)
         | Fix x_0 ->
             (Obj.magic
                [| (Obj.magic "Fix" : Js.Json.t); recur_to_json x_0 |]
               : Js.Json.t)
        : recur -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else `A
               else if Stdlib.( = ) (Obj.magic tag : string) "Fix" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else `Fix (polyrecur_of_json (Js.Array.unsafe_get array 1))
               else
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"A\"] or [\"Fix\", _]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> polyrecur)
  
    let _ = polyrecur_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec polyrecur_to_json =
      (fun x ->
         match x with
         | `A -> (Obj.magic [| (Obj.magic "A" : Js.Json.t) |] : Js.Json.t)
         | `Fix x_0 ->
             (Obj.magic
                [| (Obj.magic "Fix" : Js.Json.t); polyrecur_to_json x_0 |]
               : Js.Json.t)
        : polyrecur -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else A
               else if Stdlib.( = ) (Obj.magic tag : string) "b_aliased"
               then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else B
               else
                 Jsonkit.of_json_error ~json:x
                   "expected [\"b_aliased\"] or [\"A\"]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> evar)
  
    let _ = evar_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec evar_to_json =
      (fun x ->
         match x with
         | A -> (Obj.magic [| (Obj.magic "A" : Js.Json.t) |] : Js.Json.t)
         | B ->
             (Obj.magic [| (Obj.magic "b_aliased" : Js.Json.t) |]
               : Js.Json.t)
        : evar -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A_aliased" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else `a
               else if Stdlib.( = ) (Obj.magic tag : string) "b" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else `b
               else
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"A_aliased\"] or [\"b\"]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> epoly)
  
    let _ = epoly_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec epoly_to_json =
      (fun x ->
         match x with
         | `a ->
             (Obj.magic [| (Obj.magic "A_aliased" : Js.Json.t) |]
               : Js.Json.t)
         | `b -> (Obj.magic [| (Obj.magic "b" : Js.Json.t) |] : Js.Json.t)
        : epoly -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else A (a_of_json (Js.Array.unsafe_get array 1))
               else if Stdlib.( = ) (Obj.magic tag : string) "B" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else B (b_of_json (Js.Array.unsafe_get array 1))
               else
                 Jsonkit.of_json_error ~json:x
                   "expected [\"B\", _] or [\"A\", _]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> ('a, 'b) p2)
  
    let _ = p2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec p2_to_json a_to_json b_to_json =
      (fun x ->
         match x with
         | A x_0 ->
             (Obj.magic [| (Obj.magic "A" : Js.Json.t); a_to_json x_0 |]
               : Js.Json.t)
         | B x_0 ->
             (Obj.magic [| (Obj.magic "B" : Js.Json.t); b_to_json x_0 |]
               : Js.Json.t)
        : ('a, 'b) p2 -> Js.Json.t)
  
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs = (Obj.magic x : < a : Js.Json.t Js.undefined > Js.t) in
         {
           a =
             (match Js.Undefined.toOption fs##a with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"a\" to be present");
         }
        : Js.Json.t -> allow_extra_fields)
  
    let _ = allow_extra_fields_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec allow_extra_fields_to_json =
      (fun x ->
         match x with
         | { a = x_a } ->
             (Obj.magic [%mel.obj { a = int_to_json x_a }] : Js.Json.t)
        : allow_extra_fields -> Js.Json.t)
  
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then (
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else
                   let fs = Js.Array.unsafe_get array 1 in
                   if
                     Stdlib.not
                       (Stdlib.( && )
                          (Stdlib.( = ) (Js.typeof fs) "object")
                          (Stdlib.( && )
                             (Stdlib.not (Js.Array.isArray fs))
                             (Stdlib.not
                                (Stdlib.( == )
                                   (Obj.magic fs : 'a Js.null)
                                   Js.null))))
                   then
                     Jsonkit.of_json_error ~json:fs "expected a JSON object";
                   let fs =
                     (Obj.magic fs : < a : Js.Json.t Js.undefined > Js.t)
                   in
                   A
                     {
                       a =
                         (match Js.Undefined.toOption fs##a with
                         | Stdlib.Option.Some v -> int_of_json v
                         | Stdlib.Option.None ->
                             Jsonkit.of_json_error ~json:x
                               "expected field \"a\" to be present");
                     })
               else Jsonkit.of_json_error ~json:x "expected [\"A\", { _ }]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> allow_extra_fields2)
  
    let _ = allow_extra_fields2_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec allow_extra_fields2_to_json =
      (fun x ->
         match x with
         | A { a = x_a } ->
             (Obj.magic
                [|
                  (Obj.magic "A" : Js.Json.t);
                  (Obj.magic [%mel.obj { a = int_to_json x_a }] : Js.Json.t);
                |]
               : Js.Json.t)
        : allow_extra_fields2 -> Js.Json.t)
  
    let _ = allow_extra_fields2_to_json
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs =
           (Obj.magic x
             : < a : Js.Json.t Js.undefined
               ; b_opt : Js.Json.t Js.undefined >
               Js.t)
         in
         {
           a =
             (match Js.Undefined.toOption fs##a with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"a\" to be present");
           b_opt =
             (match Js.Undefined.toOption fs##b_opt with
             | Stdlib.Option.Some v -> (option_of_json int_of_json) v
             | Stdlib.Option.None -> Stdlib.Option.None);
         }
        : Js.Json.t -> drop_default_option)
  
    let _ = drop_default_option_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_option_to_json =
      (fun x ->
         match x with
         | { a = x_a; b_opt = x_b_opt } ->
             (Obj.magic
                [%mel.obj
                  {
                    a = int_to_json x_a;
                    b_opt =
                      (match x_b_opt with
                      | Stdlib.Option.None -> Js.Undefined.empty
                      | Stdlib.Option.Some _ ->
                          Js.Undefined.return
                            ((option_to_json int_to_json) x_b_opt));
                  }]
               : Js.Json.t)
        : drop_default_option -> Js.Json.t)
  
    let _ = drop_default_option_to_json
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs =
           (Obj.magic x
             : < a : Js.Json.t Js.undefined ; b : Js.Json.t Js.undefined >
               Js.t)
         in
         {
           a =
             (match Js.Undefined.toOption fs##a with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"a\" to be present");
           b =
             (match Js.Undefined.toOption fs##b with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None -> 1);
         }
        : Js.Json.t -> drop_default_default_eq)
  
    let _ = drop_default_default_eq_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_default_eq_to_json =
      (fun x ->
         match x with
         | { a = x_a; b = x_b } ->
             (Obj.magic
                [%mel.obj
                  {
                    a = int_to_json x_a;
                    b =
                      (if equal_int x_b 1 then Js.Undefined.empty
                       else Js.Undefined.return (int_to_json x_b));
                  }]
               : Js.Json.t)
        : drop_default_default_eq -> Js.Json.t)
  
    let _ = drop_default_default_eq_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  $ cat <<"EOF" | run
  > type variant_any = Other of Yojson.Basic.t [@allow_any] | Foo [@@deriving json]
  > EOF
  type variant_any = Other of Yojson.Basic.t [@allow_any] | Foo
  [@@deriving json]
  
  include struct
    let _ = fun (_ : variant_any) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec variant_any_of_json =
      (fun x ->
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "Foo" then
                 if Stdlib.( <> ) len 1 then Other x else Foo
               else Other x
             else Other x
           else Other x
         else Other x
        : Js.Json.t -> variant_any)
  
    let _ = variant_any_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec variant_any_to_json =
      (fun x ->
         match x with
         | Other x_0 -> x_0
         | Foo ->
             (Obj.magic [| (Obj.magic "Foo" : Js.Json.t) |] : Js.Json.t)
        : variant_any -> Js.Json.t)
  
    let _ = variant_any_to_json
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs =
           (Obj.magic x
             : < a : Js.Json.t Js.undefined ; b : Js.Json.t Js.undefined >
               Js.t)
         in
         {
           a =
             (match Js.Undefined.toOption fs##a with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"a\" to be present");
           b =
             (match Js.Undefined.toOption fs##b with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None -> 1);
         }
        : Js.Json.t -> drop_default)
  
    let _ = drop_default_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_to_json =
      (fun x ->
         match x with
         | { a = x_a; b = x_b } ->
             (Obj.magic
                [%mel.obj
                  {
                    a = int_to_json x_a;
                    b =
                      (if
                         (fun a b ->
                           if compare a b = 0 then true else false)
                           x_b 1
                       then Js.Undefined.empty
                       else Js.Undefined.return (int_to_json x_b));
                  }]
               : Js.Json.t)
        : drop_default -> Js.Json.t)
  
    let _ = drop_default_to_json
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
         if
           Stdlib.not
             (Stdlib.( && )
                (Stdlib.( = ) (Js.typeof x) "object")
                (Stdlib.( && )
                   (Stdlib.not (Js.Array.isArray x))
                   (Stdlib.not
                      (Stdlib.( == ) (Obj.magic x : 'a Js.null) Js.null))))
         then Jsonkit.of_json_error ~json:x "expected a JSON object";
         let fs =
           (Obj.magic x
             : < a : Js.Json.t Js.undefined ; b : Js.Json.t Js.undefined >
               Js.t)
         in
         {
           a =
             (match Js.Undefined.toOption fs##a with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"a\" to be present");
           b =
             (match Js.Undefined.toOption fs##b with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None -> 1);
         }
        : Js.Json.t -> drop_default_if_json_equal)
  
    let _ = drop_default_if_json_equal_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec drop_default_if_json_equal_to_json =
      (fun x ->
         match x with
         | { a = x_a; b = x_b } ->
             (Obj.magic
                [%mel.obj
                  {
                    a = int_to_json x_a;
                    b =
                      (let json = int_to_json x_b in
                       if Jsonkit.equal json (int_to_json 1) then
                         Js.Undefined.empty
                       else Js.Undefined.return json);
                  }]
               : Js.Json.t)
        : drop_default_if_json_equal -> Js.Json.t)
  
    let _ = drop_default_if_json_equal_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  $ cat <<"EOF" | run
  > type variant_any = Other of Yojson.Basic.t [@allow_any] | Foo [@@deriving json]
  > EOF
  type variant_any = Other of Yojson.Basic.t [@allow_any] | Foo
  [@@deriving json]
  
  include struct
    let _ = fun (_ : variant_any) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec variant_any_of_json =
      (fun x ->
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "Foo" then
                 if Stdlib.( <> ) len 1 then Other x else Foo
               else Other x
             else Other x
           else Other x
         else Other x
        : Js.Json.t -> variant_any)
  
    let _ = variant_any_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec variant_any_to_json =
      (fun x ->
         match x with
         | Other x_0 -> x_0
         | Foo ->
             (Obj.magic [| (Obj.magic "Foo" : Js.Json.t) |] : Js.Json.t)
        : variant_any -> Js.Json.t)
  
    let _ = variant_any_to_json
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "A" then A
               else if Stdlib.( = ) (Obj.magic tag : string) "B" then
                 if Stdlib.( <> ) len 2 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 2"
                 else B (int_of_json (Js.Array.unsafe_get array 1))
               else
                 Jsonkit.of_json_error ~json:x
                   "expected [\"B\", _] or \"A\""
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else if Stdlib.( = ) (Js.typeof x) "string" then
           if Stdlib.( = ) (Obj.magic x : string) "A" then A
           else Jsonkit.of_json_error ~json:x "expected [\"B\", _] or \"A\""
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> compact_variant)
  
    let _ = compact_variant_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec compact_variant_to_json =
      (fun x ->
         match x with
         | A -> (Obj.magic "A" : Js.Json.t)
         | B x_0 ->
             (Obj.magic [| (Obj.magic "B" : Js.Json.t); int_to_json x_0 |]
               : Js.Json.t)
        : compact_variant -> Js.Json.t)
  
    let _ = compact_variant_to_json
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
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "C" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else `C
               else
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"C\"]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> one)
  
    let _ = one_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec one_to_json =
      (fun x ->
         match x with
         | `C -> (Obj.magic [| (Obj.magic "C" : Js.Json.t) |] : Js.Json.t)
        : one -> Js.Json.t)
  
    let _ = one_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  
  type other = [ `C ] [@@deriving json]
  
  include struct
    let _ = fun (_ : other) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec other_of_json =
      (fun x ->
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               if Stdlib.( = ) (Obj.magic tag : string) "C" then
                 if Stdlib.( <> ) len 1 then
                   Jsonkit.of_json_error ~json:x
                     "expected a JSON array of length 1"
                 else `C
               else
                 Jsonkit.of_json_unexpected_variant ~json:x
                   "expected [\"C\"]"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> other)
  
    let _ = other_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec other_to_json =
      (fun x ->
         match x with
         | `C -> (Obj.magic [| (Obj.magic "C" : Js.Json.t) |] : Js.Json.t)
        : other -> Js.Json.t)
  
    let _ = other_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
  
  type poly = [ one | other ] [@@deriving json]
  
  include struct
    let _ = fun (_ : poly) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_of_json =
      (fun x ->
         if Js.Array.isArray x then
           let array = (Obj.magic x : Js.Json.t array) in
           let len = Js.Array.length array in
           if Stdlib.( > ) len 0 then
             let tag = Js.Array.unsafe_get array 0 in
             if Stdlib.( = ) (Js.typeof tag) "string" then
               match one_of_json x with
               | e -> (e :> [ one | other ])
               | exception
                   Jsonkit.Of_json_error (Jsonkit.Unexpected_variant _) -> (
                   match other_of_json x with
                   | e -> (e :> [ one | other ])
                   | exception
                       Jsonkit.Of_json_error (Jsonkit.Unexpected_variant _)
                     ->
                       Jsonkit.of_json_unexpected_variant ~json:x
                         "expected ")
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array with element being a \
                  string"
           else
             Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
         else
           Jsonkit.of_json_error ~json:x "expected a non empty JSON array"
        : Js.Json.t -> poly)
  
    let _ = poly_of_json
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec poly_to_json =
      (fun x ->
         match x with
         | #one as x -> one_to_json x
         | #other as x -> other_to_json x
        : poly -> Js.Json.t)
  
    let _ = poly_to_json
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
