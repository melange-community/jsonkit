(* Decode a JSON tree structure *)
type 'a tree = Node of 'a * 'a tree list | Leaf of 'a

module Decode = struct
  open Jsonkit.Of_json

  let rec tree decoder json =
    let node_type = field "type" string json in
    match node_type with
    | "node" -> node decoder json
    | "leaf" -> leaf decoder json
    | _ -> failwith "unknown node type"

  and node decoder json =
    Node
      ( json |> field "value" decoder,
        json
        |> field "children" (array (tree decoder) |> map Array.to_list) )

  and leaf decoder json = Leaf (json |> field "value" decoder)
end

let rec indent = function
  | n when n <= 0 -> ()
  | n ->
      print_string "  ";
      indent (n - 1)

let print =
  let rec aux level = function
    | Node (value, children) ->
        indent level;
        Js.log value;
        children |> List.iter (fun child -> aux (level + 1) child)
    | Leaf value ->
        indent level;
        Js.log value
  in
  aux 0

let json =
  {| {
  "type": "node",
  "value": 9,
  "children": [{
    "type": "node",
    "value": 5,
    "children": [{
      "type": "leaf",
      "value": 3
    }, {
      "type": "leaf",
      "value": 2
    }]
  }, {
      "type": "leaf",
      "value": 4
  }]
} |}

let myTree =
  json |> Jsonkit.of_string |> Decode.tree Jsonkit.Of_json.int |> print
