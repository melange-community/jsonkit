  $ alias run='../browser/ppx_deriving_json_js_test.exe -impl - | ocamlformat - --impl'

Builtin types are read in place:
  $ cat <<"EOF" | run
  > type ids = int list [@@deriving json_reader]
  > EOF
  type ids = int list [@@deriving json_reader]
  
  include struct
    let _ = fun (_ : ids) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec ids_json_reader =
      (fun x ->
         if Jsonkit_reader.array_start x then
           let rec json_reader_items () =
             let json_reader_item = Jsonkit_reader.int x in
             if Jsonkit_reader.more_items x then
               json_reader_item :: json_reader_items ()
             else [ json_reader_item ]
               [@@tail_mod_cons]
           in
           json_reader_items ()
         else []
        : Jsonkit_reader.t -> ids)
  
    let _ = ids_json_reader
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

A record is first read in the order its fields are declared, then in any order:
  $ cat <<"EOF" | run
  > type user = { name : string; age : int option [@json.option] } [@@deriving json_reader]
  > EOF
  type user = { name : string; age : int option [@json.option] }
  [@@deriving json_reader]
  
  include struct
    let _ = fun (_ : user) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec user_json_reader =
      (fun x ->
         let json_reader_start = Jsonkit_reader.position x in
         let json_reader_field_name =
           Stdlib.ref (Stdlib.Obj.obj Jsonkit_reader.absent)
         in
         let json_reader_field_age =
           Stdlib.ref (Stdlib.Obj.obj Jsonkit_reader.absent)
         in
         if
           Stdlib.not
             (Stdlib.( && )
                (Jsonkit_reader.speculating x)
                (Stdlib.( && )
                   (Jsonkit_reader.lit x "{\"name\":")
                   (Stdlib.( := ) json_reader_field_name
                      (Jsonkit_reader.string x);
                    if Jsonkit_reader.lit x ",\"age\":" then
                      Stdlib.( := ) json_reader_field_age
                        (if Jsonkit_reader.null x then Stdlib.Option.None
                         else Stdlib.Option.Some (Jsonkit_reader.int x));
                    Jsonkit_reader.lit x "}")))
         then (
           Jsonkit_reader.stop_speculating x json_reader_start;
           if Jsonkit_reader.object_start x then
             let json_reader_more = Stdlib.ref true in
             while Stdlib.( ! ) json_reader_more do
               let json_reader_key = Jsonkit_reader.member_start x in
               if
                 Stdlib.( && )
                   (Stdlib.( = ) json_reader_key 110)
                   (Jsonkit_reader.lit x "name\":")
               then
                 Stdlib.( := ) json_reader_field_name
                   (Jsonkit_reader.string x)
               else if
                 Stdlib.( && )
                   (Stdlib.( = ) json_reader_key 97)
                   (Jsonkit_reader.lit x "age\":")
               then
                 Stdlib.( := ) json_reader_field_age
                   (if Jsonkit_reader.null x then Stdlib.Option.None
                    else Stdlib.Option.Some (Jsonkit_reader.int x))
               else Jsonkit_reader.skip_member x;
               Stdlib.( := ) json_reader_more
                 (Jsonkit_reader.more_members x)
             done);
         {
           name =
             (if
                Stdlib.( == )
                  (Stdlib.Obj.repr (Stdlib.( ! ) json_reader_field_name))
                  Jsonkit_reader.absent
              then Jsonkit_reader.fallback ()
              else Stdlib.( ! ) json_reader_field_name);
           age =
             (if
                Stdlib.( == )
                  (Stdlib.Obj.repr (Stdlib.( ! ) json_reader_field_age))
                  Jsonkit_reader.absent
              then Stdlib.Option.None
              else Stdlib.( ! ) json_reader_field_age);
         }
        : Jsonkit_reader.t -> user)
  
    let _ = user_json_reader
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

A variant compares each tag with the input in place:
  $ cat <<"EOF" | run
  > type shape = Dot | Circle of float | Label of { text : string } [@@deriving json_reader]
  > EOF
  type shape = Dot | Circle of float | Label of { text : string }
  [@@deriving json_reader]
  
  include struct
    let _ = fun (_ : shape) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec shape_json_reader =
      (fun x ->
         if Jsonkit_reader.lit x "[\"Dot\"]" then Dot
         else if Jsonkit_reader.lit x "[\"Circle\"," then (
           let json_reader_item_0 = Jsonkit_reader.float x in
           Jsonkit_reader.char x 93;
           Circle json_reader_item_0)
         else if Jsonkit_reader.lit x "[\"Label\"," then (
           let json_reader_start = Jsonkit_reader.position x in
           let json_reader_field_text =
             Stdlib.ref (Stdlib.Obj.obj Jsonkit_reader.absent)
           in
           if
             Stdlib.not
               (Stdlib.( && )
                  (Jsonkit_reader.speculating x)
                  (Stdlib.( && )
                     (Jsonkit_reader.lit x "{\"text\":")
                     (Stdlib.( := ) json_reader_field_text
                        (Jsonkit_reader.string x);
                      Jsonkit_reader.lit x "}")))
           then (
             Jsonkit_reader.stop_speculating x json_reader_start;
             if Jsonkit_reader.object_start x then
               let json_reader_more = Stdlib.ref true in
               while Stdlib.( ! ) json_reader_more do
                 let json_reader_key = Jsonkit_reader.member_start x in
                 if
                   Stdlib.( && )
                     (Stdlib.( = ) json_reader_key 116)
                     (Jsonkit_reader.lit x "text\":")
                 then
                   Stdlib.( := ) json_reader_field_text
                     (Jsonkit_reader.string x)
                 else Jsonkit_reader.skip_member x;
                 Stdlib.( := ) json_reader_more
                   (Jsonkit_reader.more_members x)
               done);
           Jsonkit_reader.char x 93;
           Label
             {
               text =
                 (if
                    Stdlib.( == )
                      (Stdlib.Obj.repr
                         (Stdlib.( ! ) json_reader_field_text))
                      Jsonkit_reader.absent
                  then Jsonkit_reader.fallback ()
                  else Stdlib.( ! ) json_reader_field_text);
             })
         else Jsonkit_reader.fallback ()
        : Jsonkit_reader.t -> shape)
  
    let _ = shape_json_reader
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

A tuple and a type parameter:
  $ cat <<"EOF" | run
  > type 'a pair = 'a * string [@@deriving json_reader]
  > EOF
  type 'a pair = 'a * string [@@deriving json_reader]
  
  include struct
    let _ = fun (_ : 'a pair) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec pair_json_reader json_reader__a =
      (fun x ->
         Jsonkit_reader.char x 91;
         let json_reader_item_0 = json_reader__a x in
         Jsonkit_reader.char x 44;
         let json_reader_item_1 = Jsonkit_reader.string x in
         Jsonkit_reader.char x 93;
         json_reader_item_0, json_reader_item_1
        : Jsonkit_reader.t -> 'a pair)
  
    let _ = pair_json_reader
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

A referenced type needs its own reader:
  $ cat <<"EOF" | run
  > type order = { buyer : User.t; total : Money.amount } [@@deriving json_reader]
  > EOF
  type order = { buyer : User.t; total : Money.amount }
  [@@deriving json_reader]
  
  include struct
    let _ = fun (_ : order) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec order_json_reader =
      (fun x ->
         let json_reader_start = Jsonkit_reader.position x in
         let json_reader_field_buyer =
           Stdlib.ref (Stdlib.Obj.obj Jsonkit_reader.absent)
         in
         let json_reader_field_total =
           Stdlib.ref (Stdlib.Obj.obj Jsonkit_reader.absent)
         in
         if
           Stdlib.not
             (Stdlib.( && )
                (Jsonkit_reader.speculating x)
                (Stdlib.( && )
                   (Jsonkit_reader.lit x "{\"buyer\":")
                   (Stdlib.( := ) json_reader_field_buyer
                      ((User.json_reader : Jsonkit_reader.t -> User.t) x);
                    Stdlib.( && )
                      (Jsonkit_reader.lit x ",\"total\":")
                      (Stdlib.( := ) json_reader_field_total
                         ((Money.amount_json_reader
                            : Jsonkit_reader.t -> Money.amount)
                            x);
                       Jsonkit_reader.lit x "}"))))
         then (
           Jsonkit_reader.stop_speculating x json_reader_start;
           if Jsonkit_reader.object_start x then
             let json_reader_more = Stdlib.ref true in
             while Stdlib.( ! ) json_reader_more do
               let json_reader_key = Jsonkit_reader.member_start x in
               if
                 Stdlib.( && )
                   (Stdlib.( = ) json_reader_key 98)
                   (Jsonkit_reader.lit x "buyer\":")
               then
                 Stdlib.( := ) json_reader_field_buyer
                   ((User.json_reader : Jsonkit_reader.t -> User.t) x)
               else if
                 Stdlib.( && )
                   (Stdlib.( = ) json_reader_key 116)
                   (Jsonkit_reader.lit x "total\":")
               then
                 Stdlib.( := ) json_reader_field_total
                   ((Money.amount_json_reader
                      : Jsonkit_reader.t -> Money.amount)
                      x)
               else Jsonkit_reader.skip_member x;
               Stdlib.( := ) json_reader_more
                 (Jsonkit_reader.more_members x)
             done);
         {
           buyer =
             (if
                Stdlib.( == )
                  (Stdlib.Obj.repr (Stdlib.( ! ) json_reader_field_buyer))
                  Jsonkit_reader.absent
              then Jsonkit_reader.fallback ()
              else Stdlib.( ! ) json_reader_field_buyer);
           total =
             (if
                Stdlib.( == )
                  (Stdlib.Obj.repr (Stdlib.( ! ) json_reader_field_total))
                  Jsonkit_reader.absent
              then Jsonkit_reader.fallback ()
              else Stdlib.( ! ) json_reader_field_total);
         }
        : Jsonkit_reader.t -> order)
  
    let _ = order_json_reader
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

A catch-all variant is decoded through of_json:
  $ cat <<"EOF" | run
  > type event = Known of int | Other of Jsonkit.unknown_variant_case [@json.catch_all] [@@deriving json_reader]
  > EOF
  type event =
    | Known of int
    | Other of Jsonkit.unknown_variant_case [@json.catch_all]
  [@@deriving json_reader]
  
  include struct
    let _ = fun (_ : event) -> ()
  
    [@@@ocaml.warning "-39-11-27"]
  
    let rec event_json_reader =
      (fun x ->
         Jsonkit_reader.of_json
           (fun x ->
             if Js.Array.isArray x then
               let array = (Obj.magic x : Js.Json.t array) in
               let len = Js.Array.length array in
               if Stdlib.( > ) len 0 then
                 let tag = Js.Array.unsafe_get array 0 in
                 if Stdlib.( = ) (Js.typeof tag) "string" then
                   if Stdlib.( = ) (Obj.magic tag : string) "Known" then
                     if Stdlib.( <> ) len 2 then
                       Jsonkit.of_json_error ~json:x
                         "expected a JSON array of length 2"
                     else
                       Known
                         ((int_of_json : Jsonkit.Json.t -> int)
                            (Js.Array.unsafe_get array 1))
                   else
                     Other
                       (let payload =
                          if Stdlib.( = ) len 0 then Stdlib.Option.None
                          else if Stdlib.( = ) len 1 then
                            Stdlib.Option.Some []
                          else
                            let rest =
                              Stdlib.Array.sub array 1 (Stdlib.( - ) len 1)
                              |> Stdlib.Array.to_list
                              |> Stdlib.List.map (fun j -> Obj.magic j)
                            in
                            Stdlib.Option.Some rest
                        in
                        ({ tag = (Obj.magic tag : string); payload }
                          : Jsonkit.unknown_variant_case))
                 else
                   Jsonkit.of_json_error ~json:x
                     "expected a non empty JSON array with element being a \
                      string"
               else
                 Jsonkit.of_json_error ~json:x
                   "expected a non empty JSON array"
             else
               Jsonkit.of_json_error ~json:x
                 "expected a non empty JSON array")
           x
        : Jsonkit_reader.t -> event)
  
    let _ = event_json_reader
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

A signature:
  $ cat <<"EOF" | ../browser/ppx_deriving_json_js_test.exe -intf - | ocamlformat - --intf
  > type 'a pair [@@deriving json_reader]
  > EOF
  type 'a pair [@@deriving json_reader]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val pair_json_reader :
      (Jsonkit_reader.t -> 'a) -> Jsonkit_reader.t -> 'a pair
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Type parameters cannot be decoded through of_json:
  $ echo "type 'a event = Known of 'a | Other of Jsonkit.unknown_variant_case [@json.catch_all] [@@deriving json_reader]" | ../browser/ppx_deriving_json_js_test.exe -impl -
  File "-", line 1, characters 0-110:
  1 | type 'a event = Known of 'a | Other of Jsonkit.unknown_variant_case [@json.catch_all] [@@deriving json_reader]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: type parameters on a type that json_reader decodes through of_json are not supported
  [1]
