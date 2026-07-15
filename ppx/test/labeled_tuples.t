%to_json for labeled tuples:
  $ echo '
  > let _ = [%to_json: a:string * b:int]
  > ' | ./run.sh
  === ppx output:native ===
  let _ =
    fun x ->
      match x with
      | (~a:x_a, ~b:x_b) ->
          `Assoc
            (let bnds__001_ = [] in
             let bnds__001_ = ("b", (int_to_json x_b)) :: bnds__001_ in
             let bnds__001_ = ("a", (string_to_json x_a)) :: bnds__001_ in
             bnds__001_)
  === ppx output:browser ===
  let _ =
    fun x ->
      match x with
      | (~a:x_a, ~b:x_b) ->
          (Obj.magic
             ([%mel.obj { a = (string_to_json x_a); b = (int_to_json x_b) }]) : 
          Js.Json.t)
  === stdout:native ===
  === stdout:js ===

%of_json for labeled tuples:
  $ echo '
  > let _ = [%of_json: a:string * b:int]
  > ' | ./run.sh
  === ppx output:native ===
  let _ =
    fun x ->
      match x with
      | `Assoc fs ->
          let x_a = ref Stdlib.Option.None in
          let x_b = ref Stdlib.Option.None in
          let rec iter =
            function
            | [] -> ()
            | (n', v)::fs ->
                ((match n' with
                  | "a" -> x_a := (Stdlib.Option.Some (string_of_json v))
                  | "b" -> x_b := (Stdlib.Option.Some (int_of_json v))
                  | _ -> ());
                 iter fs) in
          (iter fs;
           (~a:((match Stdlib.(!) x_a with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"a\"")),
             ~b:((match Stdlib.(!) x_b with
                  | Stdlib.Option.Some v -> v
                  | Stdlib.Option.None ->
                      Jsonkit.of_json_error ~json:x "expected field \"b\""))))
      | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
  === ppx output:browser ===
  let _ =
    fun x ->
      if
        Stdlib.not
          (Stdlib.(&&) (Stdlib.(=) (Js.typeof x) "object")
             (Stdlib.(&&) (Stdlib.not (Js.Array.isArray x))
                (Stdlib.not (Stdlib.(==) (Obj.magic x : 'a Js.null) Js.null))))
      then Jsonkit.of_json_error ~json:x "expected a JSON object";
      (let fs =
         (Obj.magic x : <
                          a: Js.Json.t Js.undefined  ;b: Js.Json.t Js.undefined
                                                          > 
                          Js.t) in
       (~a:(match Js.Undefined.toOption (fs ## a) with
            | Stdlib.Option.Some v -> string_of_json v
            | Stdlib.Option.None ->
                Jsonkit.of_json_error ~json:x
                  "expected field \"a\" to be present"),
         ~b:(match Js.Undefined.toOption (fs ## b) with
             | Stdlib.Option.Some v -> int_of_json v
             | Stdlib.Option.None ->
                 Jsonkit.of_json_error ~json:x
                   "expected field \"b\" to be present")))
  === stdout:native ===
  === stdout:js ===

%to_json for partially labeled tuples (unlabeled members keyed by position):
  $ echo '
  > let _ = [%to_json: x:int * string]
  > ' | ./run.sh
  === ppx output:native ===
  let _ =
    fun x ->
      match x with
      | (~x:x_x, x_1) ->
          `Assoc
            (let bnds__001_ = [] in
             let bnds__001_ = ("1", (string_to_json x_1)) :: bnds__001_ in
             let bnds__001_ = ("x", (int_to_json x_x)) :: bnds__001_ in
             bnds__001_)
  === ppx output:browser ===
  let _ =
    fun x ->
      match x with
      | (~x:x_x, x_1) ->
          (Obj.magic
             ([%mel.obj { x = (int_to_json x_x); 1 = (string_to_json x_1) }]) : 
          Js.Json.t)
  === stdout:native ===
  === stdout:js ===

%of_json for partially labeled tuples (unlabeled members keyed by position):
  $ echo '
  > let _ = [%of_json: x:int * string]
  > ' | ./run.sh
  === ppx output:native ===
  let _ =
    fun x ->
      match x with
      | `Assoc fs ->
          let x_x = ref Stdlib.Option.None in
          let x_1 = ref Stdlib.Option.None in
          let rec iter =
            function
            | [] -> ()
            | (n', v)::fs ->
                ((match n' with
                  | "x" -> x_x := (Stdlib.Option.Some (int_of_json v))
                  | "1" -> x_1 := (Stdlib.Option.Some (string_of_json v))
                  | _ -> ());
                 iter fs) in
          (iter fs;
           (~x:((match Stdlib.(!) x_x with
                 | Stdlib.Option.Some v -> v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x "expected field \"x\"")),
             ((match Stdlib.(!) x_1 with
               | Stdlib.Option.Some v -> v
               | Stdlib.Option.None ->
                   Jsonkit.of_json_error ~json:x "expected field \"1\""))))
      | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object"
  === ppx output:browser ===
  let _ =
    fun x ->
      if
        Stdlib.not
          (Stdlib.(&&) (Stdlib.(=) (Js.typeof x) "object")
             (Stdlib.(&&) (Stdlib.not (Js.Array.isArray x))
                (Stdlib.not (Stdlib.(==) (Obj.magic x : 'a Js.null) Js.null))))
      then Jsonkit.of_json_error ~json:x "expected a JSON object";
      (let fs =
         (Obj.magic x : <
                          x: Js.Json.t Js.undefined  ;1: Js.Json.t Js.undefined
                                                          > 
                          Js.t) in
       (~x:(match Js.Undefined.toOption (fs ## x) with
            | Stdlib.Option.Some v -> int_of_json v
            | Stdlib.Option.None ->
                Jsonkit.of_json_error ~json:x
                  "expected field \"x\" to be present"),
         (match Js.Undefined.toOption (fs ## 1) with
          | Stdlib.Option.Some v -> string_of_json v
          | Stdlib.Option.None ->
              Jsonkit.of_json_error ~json:x
                "expected field \"1\" to be present")))
  === stdout:native ===
  === stdout:js ===

[@@deriving json] on a named labeled-tuple type:
  $ echo '
  > type point = (x:int * y:int) [@@deriving json]
  > ' | ./run.sh
  === ppx output:native ===
  type point = (x:int * y:int)[@@deriving json]
  include
    struct
      let _ = fun (_ : point) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec point_of_json =
        (fun x ->
           match x with
           | `Assoc fs ->
               let x_x = ref Stdlib.Option.None in
               let x_y = ref Stdlib.Option.None in
               let rec iter =
                 function
                 | [] -> ()
                 | (n', v)::fs ->
                     ((match n' with
                       | "x" -> x_x := (Stdlib.Option.Some (int_of_json v))
                       | "y" -> x_y := (Stdlib.Option.Some (int_of_json v))
                       | _ -> ());
                      iter fs) in
               (iter fs;
                (~x:((match Stdlib.(!) x_x with
                      | Stdlib.Option.Some v -> v
                      | Stdlib.Option.None ->
                          Jsonkit.of_json_error ~json:x "expected field \"x\"")),
                  ~y:((match Stdlib.(!) x_y with
                       | Stdlib.Option.Some v -> v
                       | Stdlib.Option.None ->
                           Jsonkit.of_json_error ~json:x "expected field \"y\""))))
           | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object" : 
        Yojson.Basic.t -> point)
      let _ = point_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec point_to_json =
        (fun x ->
           match x with
           | (~x:x_x, ~y:x_y) ->
               `Assoc
                 (let bnds__001_ = [] in
                  let bnds__001_ = ("y", (int_to_json x_y)) :: bnds__001_ in
                  let bnds__001_ = ("x", (int_to_json x_x)) :: bnds__001_ in
                  bnds__001_) : point -> Yojson.Basic.t)
      let _ = point_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  === ppx output:browser ===
  type point = (x:int * y:int)[@@deriving json]
  include
    struct
      let _ = fun (_ : point) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec point_of_json =
        (fun x ->
           if
             Stdlib.not
               (Stdlib.(&&) (Stdlib.(=) (Js.typeof x) "object")
                  (Stdlib.(&&) (Stdlib.not (Js.Array.isArray x))
                     (Stdlib.not
                        (Stdlib.(==) (Obj.magic x : 'a Js.null) Js.null))))
           then Jsonkit.of_json_error ~json:x "expected a JSON object";
           (let fs =
              (Obj.magic x : <
                               x: Js.Json.t Js.undefined  ;y: Js.Json.t
                                                                Js.undefined  
                               >  Js.t) in
            (~x:(match Js.Undefined.toOption (fs ## x) with
                 | Stdlib.Option.Some v -> int_of_json v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x
                       "expected field \"x\" to be present"),
              ~y:(match Js.Undefined.toOption (fs ## y) with
                  | Stdlib.Option.Some v -> int_of_json v
                  | Stdlib.Option.None ->
                      Jsonkit.of_json_error ~json:x
                        "expected field \"y\" to be present"))) : Js.Json.t ->
                                                                    point)
      let _ = point_of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec point_to_json =
        (fun x ->
           match x with
           | (~x:x_x, ~y:x_y) ->
               (Obj.magic
                  ([%mel.obj { x = (int_to_json x_x); y = (int_to_json x_y) }]) : 
               Js.Json.t) : point -> Js.Json.t)
      let _ = point_to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  === stdout:native ===
  === stdout:js ===

[@@deriving json] on a named partially-labeled tuple type:
  $ echo '
  > type t = (x:int * string) [@@deriving json]
  > ' | ./run.sh
  === ppx output:native ===
  type t = (x:int * string)[@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           match x with
           | `Assoc fs ->
               let x_x = ref Stdlib.Option.None in
               let x_1 = ref Stdlib.Option.None in
               let rec iter =
                 function
                 | [] -> ()
                 | (n', v)::fs ->
                     ((match n' with
                       | "x" -> x_x := (Stdlib.Option.Some (int_of_json v))
                       | "1" -> x_1 := (Stdlib.Option.Some (string_of_json v))
                       | _ -> ());
                      iter fs) in
               (iter fs;
                (~x:((match Stdlib.(!) x_x with
                      | Stdlib.Option.Some v -> v
                      | Stdlib.Option.None ->
                          Jsonkit.of_json_error ~json:x "expected field \"x\"")),
                  ((match Stdlib.(!) x_1 with
                    | Stdlib.Option.Some v -> v
                    | Stdlib.Option.None ->
                        Jsonkit.of_json_error ~json:x "expected field \"1\""))))
           | _ -> Jsonkit.of_json_error ~json:x "expected a JSON object" : 
        Yojson.Basic.t -> t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | (~x:x_x, x_1) ->
               `Assoc
                 (let bnds__001_ = [] in
                  let bnds__001_ = ("1", (string_to_json x_1)) :: bnds__001_ in
                  let bnds__001_ = ("x", (int_to_json x_x)) :: bnds__001_ in
                  bnds__001_) : t -> Yojson.Basic.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  === ppx output:browser ===
  type t = (x:int * string)[@@deriving json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec of_json =
        (fun x ->
           if
             Stdlib.not
               (Stdlib.(&&) (Stdlib.(=) (Js.typeof x) "object")
                  (Stdlib.(&&) (Stdlib.not (Js.Array.isArray x))
                     (Stdlib.not
                        (Stdlib.(==) (Obj.magic x : 'a Js.null) Js.null))))
           then Jsonkit.of_json_error ~json:x "expected a JSON object";
           (let fs =
              (Obj.magic x : <
                               x: Js.Json.t Js.undefined  ;1: Js.Json.t
                                                                Js.undefined  
                               >  Js.t) in
            (~x:(match Js.Undefined.toOption (fs ## x) with
                 | Stdlib.Option.Some v -> int_of_json v
                 | Stdlib.Option.None ->
                     Jsonkit.of_json_error ~json:x
                       "expected field \"x\" to be present"),
              (match Js.Undefined.toOption (fs ## 1) with
               | Stdlib.Option.Some v -> string_of_json v
               | Stdlib.Option.None ->
                   Jsonkit.of_json_error ~json:x
                     "expected field \"1\" to be present"))) : Js.Json.t -> t)
      let _ = of_json
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | (~x:x_x, x_1) ->
               (Obj.magic
                  ([%mel.obj
                     { x = (int_to_json x_x); 1 = (string_to_json x_1) }]) : 
               Js.Json.t) : t -> Js.Json.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  === stdout:native ===
  === stdout:js ===
