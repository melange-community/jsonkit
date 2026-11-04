
  $ echo "module type S = sig type ('a, 'b) either [@@deriving json] end" | ./run.sh
  === ppx output:native ===
  module type S  =
    sig
      type ('a, 'b) either[@@deriving json]
      include
        sig
          [@@@ocaml.warning "-32"]
          val either_of_json :
            (Jsonkit.Json.t -> 'a) ->
              (Jsonkit.Json.t -> 'b) -> Jsonkit.Json.t -> ('a, 'b) either
          val either_to_json :
            ('a -> Jsonkit.Json.t) ->
              ('b -> Jsonkit.Json.t) -> ('a, 'b) either -> Jsonkit.Json.t
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
            (Jsonkit.Json.t -> 'a) ->
              (Jsonkit.Json.t -> 'b) -> Jsonkit.Json.t -> ('a, 'b) either
          val either_to_json :
            ('a -> Jsonkit.Json.t) ->
              ('b -> Jsonkit.Json.t) -> ('a, 'b) either -> Jsonkit.Json.t
        end[@@ocaml.doc "@inline"][@@merlin.hide ]
    end
  === stdout:native ===
  === stdout:js ===
