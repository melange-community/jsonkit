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
  
      let foo_to_json_buffer =
        (fun x -> foo_to_json_buffer x : foo -> Stdlib.Buffer.t -> unit)
  
      let _ = foo_to_json_buffer
  
      [@@@ocaml.warning "-39-11-27"]
  
      let foo_of_json = (fun x -> foo_of_json x : Yojson.Basic.t -> foo)
      let _ = foo_of_json
  
      [@@@ocaml.warning "-39-11-27"]
  
      let foo_to_json = (fun x -> foo_to_json x : foo -> Yojson.Basic.t)
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
  
      let foo_of_json = (fun x -> foo_of_json x : Js.Json.t -> foo)
      let _ = foo_of_json
  
      [@@@ocaml.warning "-39-11-27"]
  
      let foo_to_json = (fun x -> foo_to_json x : foo -> Js.Json.t)
      let _ = foo_to_json
    end [@@ocaml.doc "@inline"] [@@merlin.hide]
  end
