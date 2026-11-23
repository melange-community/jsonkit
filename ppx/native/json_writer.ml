open StdLabels
open Ppxlib
open Ast_builder.Default
open Conv

let with_buffer ~loc f =
  let name = gen_symbol ~prefix:"_buf" () in
  [%expr fun [%p pvar ~loc name] -> [%e f (evar ~loc name)]]

let add_string ~loc b s =
  [%expr Stdlib.Buffer.add_string [%e b] [%e estring ~loc s]]

let add_char ~loc b c =
  [%expr Stdlib.Buffer.add_char [%e b] [%e echar ~loc c]]

let is_plain_key key =
  let plain = ref true in
  String.iter key ~f:(fun c ->
      let code = Char.code c in
      if code < 0x20 || code >= 0x7f || c = '"' || c = '\\' then
        plain := false);
  !plain

let quoted key = "\"" ^ key ^ "\":"
let quoted_string text = "\"" ^ text ^ "\""

type chunk = Literal of string | Write of expression

let literal_of expression =
  match expression with
  | [%expr
      Jsonkit.Writer.literal
        [%e?
          { pexp_desc = Pexp_constant (Pconst_string (text, _, _)); _ }]]
    ->
      Some text
  | _ -> None

let rec merge = function
  | Literal a :: Literal b :: rest -> merge (Literal (a ^ b) :: rest)
  | chunk :: rest -> chunk :: merge rest
  | [] -> []

let emit ~loc b chunks =
  esequence ~loc
    (List.map (merge chunks) ~f:(function
      | Literal text ->
          if String.length text = 1 then add_char ~loc b text.[0]
          else add_string ~loc b text
      | Write expression -> [%expr [%e expression] [%e b]]))

let json_array ~loc es =
  let items =
    List.mapi es ~f:(fun i e ->
        let write =
          match literal_of e with
          | Some text -> Literal text
          | None -> Write e
        in
        if i = 0 then [ write ] else [ Literal ","; write ])
    |> List.concat
  in
  with_buffer ~loc (fun b ->
      emit ~loc b ((Literal "[" :: items) @ [ Literal "]" ]))

let json_string ~loc (n : label loc) =
  if is_plain_key n.txt then
    [%expr
      Jsonkit.Writer.literal [%e estring ~loc:n.loc (quoted_string n.txt)]]
  else [%expr Jsonkit.Writer.string [%e estring ~loc:n.loc n.txt]]

let catch_all_encode ~loc ~tag ~payload =
  with_buffer ~loc (fun b ->
      [%expr
        match [%e payload] with
        | Stdlib.Option.None -> Jsonkit.Writer.string [%e tag] [%e b]
        | Stdlib.Option.Some xs ->
            Stdlib.Buffer.add_char [%e b] '[';
            Jsonkit.Writer.string [%e tag] [%e b];
            Stdlib.List.iter
              (fun x ->
                Stdlib.Buffer.add_char [%e b] ',';
                Jsonkit.Writer.json x [%e b])
              xs;
            Stdlib.Buffer.add_char [%e b] ']'])

let derive_of_record ~loc derive (fields : Record.to_field list) es =
  let is_static (f : Record.to_field) =
    match f.drop with `No -> is_plain_key f.key.txt | _ -> false
  in
  let fields_and_values = List.combine fields es in
  if List.for_all fields ~f:is_static then
    with_buffer ~loc (fun b ->
        match fields_and_values with
        | [] -> add_string ~loc b "{}"
        | fields_and_values ->
            let writes =
              List.mapi fields_and_values
                ~f:(fun i ((f : Record.to_field), x) ->
                  [
                    add_string ~loc b
                      ((if i = 0 then "{" else ",") ^ quoted f.key.txt);
                    [%expr [%e derive f.type_ x] [%e b]];
                  ])
              |> List.concat
            in
            esequence ~loc (writes @ [ add_char ~loc b '}' ]))
  else
    let o = gen_symbol ~prefix:"_obj" () in
    let key (f : Record.to_field) =
      let loc = f.key.loc in
      if is_plain_key f.key.txt then
        [%expr
          Jsonkit.Writer.key [%e evar ~loc o]
            [%e estring ~loc (quoted f.key.txt)]]
      else
        [%expr
          Jsonkit.Writer.key_escaped [%e evar ~loc o]
            [%e estring ~loc f.key.txt]]
    in
    let field ((f : Record.to_field), x) =
      let loc = f.key.loc in
      let write = [%expr [%e derive f.type_ x] [%e key f]] in
      match f.drop with
      | `No -> write
      | `Drop_option ->
          [%expr
            match [%e x] with
            | Stdlib.Option.None -> ()
            | Stdlib.Option.Some _ -> [%e write]]
      | `Drop_default (equal, default) ->
          [%expr
            if [%e equal] [%e x] [%e default] then () else [%e write]]
      | `Drop_default_if_json_equal default ->
          [%expr
            let written =
              Jsonkit.Writer.to_string
                (fun () -> [%e derive f.type_ x])
                ()
            in
            if
              Stdlib.String.equal written
                (Jsonkit.Writer.to_string
                   (fun () -> [%e derive f.type_ default])
                   ())
            then ()
            else Stdlib.Buffer.add_string [%e key f] written]
    in
    with_buffer ~loc (fun b ->
        [%expr
          Jsonkit.Writer.obj [%e b] (fun [%p pvar ~loc o] ->
              [%e esequence ~loc (List.map fields_and_values ~f:field)])])

let allow_any_encode ~loc x = [%expr Jsonkit.Writer.json [%e x]]

let has_own_writer (n : longident loc) =
  match Longident.flatten_exn n.txt with
  | [ ("int" | "int64" | "float" | "string" | "bool" | "unit") ] -> true
  | [ "Jsonkit"; "t" ] | [ "Yojson"; "Basic"; "t" ] -> true
  | _ -> false

let type_ref ~loc n ts =
  match !Json_writer_mode.current, ts with
  | Json_writer_mode.Via_json, [] when not (has_own_writer n) ->
      Some
        [%expr
          Jsonkit.Writer.via_to_json [%e Ast_helpers.ederiver "to_json" n]]
  | _ -> None

let deriving : Conv.deriving =
  deriving_to () ~name:"to_json_buffer" ~type_ref
    ~t_to:(fun ~loc -> [%type: Stdlib.Buffer.t -> unit])
    ~json_array ~json_string ~catch_all_encode ~allow_any_encode
    ~derive_of_record
