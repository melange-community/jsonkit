[@@@alert "-deprecated"]

open Jest
open Expect
open Jsonkit

let () =
  describe "parse" (fun () ->
      test "success" (fun () ->
          expect @@ parse "null" |> toEqual (Some Encode.null));

      test "error" (fun () -> expect @@ parse "{" |> toEqual None));

  describe "parseOrRaise" (fun () ->
      test "success" (fun () ->
          expect @@ parseOrRaise "null" |> toEqual Encode.null);

      test "error" (fun () ->
          try
            let (_ : Js.Json.t) = parseOrRaise "{" in
            fail "should throw"
          with
          | ParseError "Unexpected end of JSON input"
          | ParseError
              (* Node.js v20 *)
              "Expected property name or '}' in JSON at position 1"
          | ParseError
              (* Node.js v21 *)
              "Expected property name or '}' in JSON at position 1 (line \
               1 column 2)"
          ->
            pass));

  test "stringify" (fun () ->
      expect @@ stringify Encode.null |> toEqual "null")
