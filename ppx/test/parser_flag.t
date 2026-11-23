The native ppx takes `-parser=direct|yojson`, which decides how a derived
writer reaches the types it references.

  $ show_native() { ../native/ppx_deriving_json_native_test.exe "$@" -impl - | ocamlformat - --impl | awk '/let rec row_to_json_buffer/,/^$/'; }

By default a reference to another type uses that type's own writer, so the
type has to be derived too:

  $ cat <<"EOF" | show_native
  > type row = { id : Id.t; names : string list } [@@deriving json]
  > EOF
    let rec row_to_json_buffer =
      (fun x ->
         match x with
         | { id = x_id; names = x_names } ->
             fun _buf__002_ ->
               Stdlib.Buffer.add_string _buf__002_ "{\"id\":";
               (Id.to_json_buffer x_id) _buf__002_;
               Stdlib.Buffer.add_string _buf__002_ ",\"names\":";
               ((list_to_json_buffer string_to_json_buffer) x_names)
                 _buf__002_;
               Stdlib.Buffer.add_char _buf__002_ '}'
        : row -> Stdlib.Buffer.t -> unit)
  

With `-parser=yojson` the same reference goes through that type's `to_json`
instead, so a module whose converters are written by hand needs no writer.
Primitives and type arguments keep their own writers:

  $ cat <<"EOF" | show_native -parser=yojson
  > type row = { id : Id.t; names : string list } [@@deriving json]
  > EOF
    let rec row_to_json_buffer =
      (fun x ->
         match x with
         | { id = x_id; names = x_names } ->
             fun _buf__002_ ->
               Stdlib.Buffer.add_string _buf__002_ "{\"id\":";
               ((Jsonkit.Writer.via_to_json Id.to_json) x_id) _buf__002_;
               Stdlib.Buffer.add_string _buf__002_ ",\"names\":";
               ((list_to_json_buffer string_to_json_buffer) x_names)
                 _buf__002_;
               Stdlib.Buffer.add_char _buf__002_ '}'
        : row -> Stdlib.Buffer.t -> unit)
  

An unknown value is rejected:

  $ echo 'type t = int [@@deriving json]' | ../native/ppx_deriving_json_native_test.exe -parser=tree -impl - 2>&1 | head -1
  ../native/ppx_deriving_json_native_test.exe: -parser: expected direct or yojson, got tree.
