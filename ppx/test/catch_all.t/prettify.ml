(* [@json.catch_all] marks the constructor that absorbs any unrecognised
   string tag during decoding. The constructor's argument is the library
   type [Jsonkit.unknown_variant_case], a record with fields
   [{ tag : string; payload : Jsonkit.t list option }]. The decoder
   captures both bare-string and array wire shapes losslessly; the encoder
   re-emits the captured wire shape. *)

type sum_enum =
  | Alpha [@json.name "alpha"]
  | Beta of int [@json.name "beta"]
  | Other of Jsonkit.unknown_variant_case [@json.catch_all]
[@@deriving json] [@@json.compact_variants]

type poly_enum =
  [ `Alpha [@json.name "alpha"]
  | `Beta of int [@json.name "beta"]
  | `Other of Jsonkit.unknown_variant_case [@json.catch_all]
  ]
[@@deriving json] [@@json.compact_variants]

let pp_unknown { Jsonkit.tag; payload } =
  match payload with
  | None -> Printf.sprintf "Other(%s,bare)" tag
  | Some xs -> Printf.sprintf "Other(%s,[%s])" tag (String.concat ";" (List.map Yojson.Basic.to_string xs))

let pp = function
  | Alpha -> "Alpha"
  | Beta n -> Printf.sprintf "Beta(%d)" n
  | Other u -> pp_unknown u

let pp_poly (v : poly_enum) =
  match v with
  | `Alpha -> "Alpha"
  | `Beta n -> Printf.sprintf "Beta(%d)" n
  | `Other u -> pp_unknown u

let () =
  let json = Yojson.Basic.from_string Sys.argv.(1) in
  let kind = Sys.argv.(2) in
  let in_s = Yojson.Basic.to_string json in
  match kind with
  | "sum" ->
    let v = sum_enum_of_json json in
    Printf.printf "got %s\n" (pp v);
    Printf.printf "round-trip %s -> %s\n" in_s (Yojson.Basic.to_string (sum_enum_to_json v))
  | "poly" ->
    let v = poly_enum_of_json json in
    Printf.printf "got %s\n" (pp_poly v);
    Printf.printf "round-trip %s -> %s\n" in_s (Yojson.Basic.to_string (poly_enum_to_json v))
  | _ -> failwith "kind must be sum or poly"
