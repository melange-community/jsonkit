  $ show_native() { ../native/ppx_deriving_json_native_test.exe -impl - | ocamlformat - --impl | awk '/module X = struct/,/^end$/'; }

  $ cat <<"EOF" | show_native
  > type foo = A | B [@@deriving json]
  > module X = struct
  >   type nonrec foo = foo [@@deriving json]
  > end
  > EOF
  module X = struct
    type nonrec foo = foo [@@deriving json]
  
    include struct
      let _ = fun (_ : foo) -> ()
  
      [@@@ocaml.warning "-39-11-27"]
  
      let foo_of_json =
        (fun x -> (foo_of_json : Jsonkit.Json.t -> foo) x
          : Jsonkit.Json.t -> foo)
  
      let _ = foo_of_json
  
      [@@@ocaml.warning "-39-11-27"]
  
      let foo_to_json =
        (fun x -> (foo_to_json : foo -> Jsonkit.Json.t) x
          : foo -> Jsonkit.Json.t)
  
      let _ = foo_to_json
    end [@@ocaml.doc "@inline"] [@@merlin.hide]
  end

  $ show_js() { ../browser/ppx_deriving_json_js_test.exe -impl - | ocamlformat - --impl | awk '/module X = struct/,/^end$/'; }

  $ cat <<"EOF" | show_js
  > type foo = A | B [@@deriving json]
  > module X = struct
  >   type nonrec foo = foo [@@deriving json]
  > end
  > EOF
  module X = struct
    type nonrec foo = foo [@@deriving json]
  
    include struct
      let _ = fun (_ : foo) -> ()
  
      [@@@ocaml.warning "-39-11-27"]
  
      let foo_of_json =
        (fun x -> (foo_of_json : Jsonkit.Json.t -> foo) x
          : Jsonkit.Json.t -> foo)
  
      let _ = foo_of_json
  
      [@@@ocaml.warning "-39-11-27"]
  
      let foo_to_json =
        (fun x -> (foo_to_json : foo -> Jsonkit.Json.t) x
          : foo -> Jsonkit.Json.t)
  
      let _ = foo_to_json
    end [@@ocaml.doc "@inline"] [@@merlin.hide]
  end
