type line = { start : point; end_ : point; thickness : int option }
and point = { x : int; y : int }

module Of_json = struct
  let point json =
    Jsonkit.Of_json.
      { x = json |> field "x" int; y = json |> field "y" int }

  let line json =
    Jsonkit.Of_json.
      {
        start = json |> field "start" point;
        end_ = json |> field "end" point;
        thickness = json |> try_or_none (field "thickness" int);
      }
end

let data =
  {| {
  "start": { "x": 1, "y": -4 },
  "end":   { "x": 5, "y": 8 }
} |}

let _ = data |> Jsonkit.of_string |> Of_json.line |> Js.log
