
  $ echo "module type S = sig type ('a, 'b) either [@@deriving json] end" | ./run.sh
  === ppx output:native ===
  module type S  =
    sig
      type ('a, 'b) either[@@deriving json]
      include
        sig
          [@@@ocaml.warning "-32"]
          val either_to_json_buffer :
            ('a -> Stdlib.Buffer.t -> unit) ->
              ('b -> Stdlib.Buffer.t -> unit) ->
                ('a, 'b) either -> Stdlib.Buffer.t -> unit
          val either_of_json :
            (Yojson.Basic.t -> 'a) ->
              (Yojson.Basic.t -> 'b) -> Yojson.Basic.t -> ('a, 'b) either
          val either_to_json :
            ('a -> Yojson.Basic.t) ->
              ('b -> Yojson.Basic.t) -> ('a, 'b) either -> Yojson.Basic.t
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end
  === ppx output:browser ===
  module type S  =
    sig
      type ('a, 'b) either[@@deriving json]
      include
        sig
          [@@@ocaml.warning "-32"]
          val either_of_json :
            (Js.Json.t -> 'a) ->
              (Js.Json.t -> 'b) -> Js.Json.t -> ('a, 'b) either
          val either_to_json :
            ('a -> Js.Json.t) ->
              ('b -> Js.Json.t) -> ('a, 'b) either -> Js.Json.t
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end
  === stdout:native ===
  === stdout:js ===
