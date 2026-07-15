We can classify the JSON produced by `to_json` for a record with a dropped optional field:
  $ echo '
  > open Jsonkit.Primitives
  > type t = {a: int option; [@json.option] [@json.drop_default]} [@@deriving to_json]
  > let () =
  >   match Jsonkit.classify (to_json {a = None}) with
  >   | `Assoc xs -> xs |> List.iter (fun (k, v) ->
  >       let _ = k in
  >       let _v = Jsonkit.classify v in
  >       ());
  >       print_endline "OK"
  >   | _ -> print_endline "ERROR: Expected an object"
  > ' | ./run.sh
  === ppx output:native ===
  open Jsonkit.Primitives
  type t = {
    a: int option [@json.option ][@json.drop_default ]}[@@deriving to_json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | { a = x_a } ->
               `Assoc
                 (let bnds__001_ = [] in
                  let bnds__001_ =
                    match x_a with
                    | Stdlib.Option.None -> bnds__001_
                    | Stdlib.Option.Some _ ->
                        ("a", ((option_to_json int_to_json) x_a)) :: bnds__001_ in
                  bnds__001_) : t -> Yojson.Basic.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    match Jsonkit.classify (to_json { a = None }) with
    | `Assoc xs ->
        (xs |>
           (List.iter
              (fun (k, v) -> let _ = k in let _v = Jsonkit.classify v in ()));
         print_endline "OK")
    | _ -> print_endline "ERROR: Expected an object"
  === ppx output:browser ===
  open Jsonkit.Primitives
  type t = {
    a: int option [@json.option ][@json.drop_default ]}[@@deriving to_json]
  include
    struct
      let _ = fun (_ : t) -> ()
      [@@@ocaml.warning "-39-11-27"]
      let rec to_json =
        (fun x ->
           match x with
           | { a = x_a } ->
               (Obj.magic
                  ([%mel.obj
                     {
                       a =
                         (match x_a with
                          | Stdlib.Option.None -> Js.Undefined.empty
                          | Stdlib.Option.Some _ ->
                              Js.Undefined.return
                                ((option_to_json int_to_json) x_a))
                     }]) : Js.Json.t) : t -> Js.Json.t)
      let _ = to_json
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  let () =
    match Jsonkit.classify (to_json { a = None }) with
    | `Assoc xs ->
        (xs |>
           (List.iter
              (fun (k, v) -> let _ = k in let _v = Jsonkit.classify v in ()));
         print_endline "OK")
    | _ -> print_endline "ERROR: Expected an object"
  === stdout:native ===
  OK
  === stdout:js ===
  OK
