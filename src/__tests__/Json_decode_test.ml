[@@@alert "-deprecated"]

open Jest
open Expect

exception Foo

module Test = struct
  type default_case =
    | Float
    | Int
    | String
    | Null
    | Array
    | Object
    | Bool
    | Char

  let valueFor =
    let open! Jsonkit.Encode in
    function
    | Float -> float 1.23
    | Int -> int 23
    | String -> string "test"
    | Null -> null
    | Array -> jsonArray [||]
    | Object -> object_ []
    | Bool -> bool true
    | Char -> char 'a'

  let throws ?(name = "throws") decoder kinds =
    testAll name (List.map valueFor kinds) (fun value ->
        try
          let _ = decoder value in
          fail "should throw"
        with Jsonkit.Of_json_error _ -> pass)
end

let wrap_exn exp =
  try
    let _ = exp () in
    "not called"
  with Jsonkit.Of_json_error str -> Jsonkit.of_json_error_to_string str

let () =
  describe "id" (fun () ->
      let open Jsonkit in
      let open Decode in
      test "id" (fun () ->
          expect @@ int (0 |> Encode.int |> Decode.id) |> toEqual 0));

  describe "bool" (fun () ->
      let open Jsonkit in
      let open Decode in
      test "bool" (fun () ->
          expect @@ bool (Encode.bool true) |> toEqual true);
      test "bool - false" (fun () ->
          expect @@ bool (Encode.bool false) |> toEqual false);

      Test.throws bool [ Float; Int; String; Null; Array; Object; Char ]);

  describe "float" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "float" (fun () ->
          expect @@ float (Encode.float 1.23) |> toEqual 1.23);
      test "int" (fun () ->
          expect @@ float (Encode.int 23) |> toEqual 23.);

      Test.throws float [ Bool; String; Null; Array; Object; Char ]);

  describe "int" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "int" (fun () -> expect @@ int (Encode.int 23) |> toEqual 23);

      test "int > 32-bit" (fun () ->
          (* Use %raw since integer literals > Int32.max_int overflow without warning *)
          let big_int = [%raw "2147483648"] in
          expect @@ int (Encode.int big_int) |> toEqual big_int);
      test "infinity" (fun () ->
          (* does this test make sense? it uses `Infinity` which is picked as
             float at runtime so the error is weird *)
          let inf = [%raw "Infinity"] in
          expect
          @@ wrap_exn (fun () ->
              let (_ : int) = int (Encode.int inf) in
              fail "should throw")
          |> toEqual "expected an integer but got inf");

      Test.throws int [ Bool; Float; String; Null; Array; Object; Char ]);

  describe "string" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "string" (fun () ->
          expect @@ string (Encode.string "test") |> toEqual "test");

      test "single-character string" (fun () ->
          expect @@ string (Encode.char 'a') |> toEqual "a");

      test "object as string" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string) =
                string (Encode.jsonDict (Js.Dict.empty ()))
              in
              fail "should throw")
          |> toEqual "expected a string but got {}");

      Test.throws string [ Bool; Float; Int; Null; Array; Object ]);

  describe "date" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "ISO8601-formatted string" (fun () ->
          expect @@ date (Encode.string "2012-04-23T18:25:43.511Z")
          |> toEqual (Js.Date.fromString "2012-04-23T18:25:43.511Z"));

      Test.throws date [ Bool; Float; Int; Null; Array; Object ]);

  describe "char" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "character" (fun () ->
          expect @@ char (Encode.char 'a') |> toEqual 'a');

      test "single-character string" (fun () ->
          expect @@ char (Encode.string "a") |> toEqual 'a');

      test "empty string" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : char) = char (Encode.string "") in
              fail "should throw")
          |> toEqual "expected a single-character string but got \"\"");

      test "multiple-character string" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : char) = char (Encode.string "abc") in
              fail "should throw")
          |> toEqual "expected a single-character string but got \"abc\"");

      Test.throws char [ Bool; Float; Int; Null; Array; Object ]);

  describe "nullable" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "int -> int" (fun () ->
          expect @@ (nullable int) (Encode.int 23)
          |> toEqual (Js.Null.return 23));
      test "null -> int" (fun () ->
          expect @@ (nullable int) Encode.null |> toEqual Js.null);

      test "boolean -> boolean " (fun () ->
          expect @@ nullable bool (Encode.bool true)
          |> toEqual (Js.Null.return true));
      test "float -> float" (fun () ->
          expect @@ nullable float (Encode.float 1.23)
          |> toEqual (Js.Null.return 1.23));
      test "string -> string" (fun () ->
          expect @@ nullable string (Encode.string "test")
          |> toEqual (Js.Null.return "test"));
      test "null -> null" (fun () ->
          expect @@ nullable (nullAs Js.null) Encode.null
          |> toEqual Js.null);

      Test.throws (nullable int)
        [ Bool; Float; String; Array; Object; Char ];
      Test.throws (nullable bool) [ Int ]);

  describe "nullAs" (fun () ->
      let open Jsonkit in
      let open Decode in
      test "as 0 - null" (fun () ->
          expect @@ (nullAs 0) Encode.null |> toEqual 0);

      test "as Js.null" (fun () ->
          expect (nullAs Js.null Encode.null) |> toEqual Js.null);
      test "as None" (fun () ->
          expect (nullAs None Encode.null) |> toEqual None);
      test "as Some _" (fun () ->
          expect (nullAs (Some "foo") Encode.null) |> toEqual (Some "foo"));

      Test.throws (nullAs 0)
        [ Bool; Float; Int; String; Array; Object; Char ]);

  describe "array" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "array" (fun () ->
          expect @@ (array int) (Encode.jsonArray [||]) |> toEqual [||]);

      test "boolean" (fun () ->
          expect @@ array bool (parseOrRaise {| [true, false, true] |})
          |> toEqual [| true; false; true |]);
      test "float" (fun () ->
          expect @@ array float (parseOrRaise {| [1, 2, 3] |})
          |> toEqual [| 1.; 2.; 3. |]);
      test "int" (fun () ->
          expect @@ array int (parseOrRaise {| [1, 2, 3] |})
          |> toEqual [| 1; 2; 3 |]);
      test "string" (fun () ->
          expect @@ array string (parseOrRaise {| ["a", "b", "c"] |})
          |> toEqual [| "a"; "b"; "c" |]);
      test "nullAs" (fun () ->
          expect
          @@ array (nullAs Js.null)
               (parseOrRaise {| [null, null, null] |})
          |> toEqual [| Js.null; Js.null; Js.null |]);

      test "array int -> array boolean" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : bool array) =
                (array bool) (parseOrRaise {| [1, 2, 3] |})
              in
              fail "should throw")
          |> toEqual "expected a boolean but got 1\n\tin array at index 0");

      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : _ array) =
              (array (fun _ -> raise Foo))
                (Encode.array Encode.int [| 1 |])
            in
            fail "should throw"
          with Foo -> pass);

      Test.throws (array int)
        [ Bool; Float; Int; String; Null; Object; Char ]);

  describe "list" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "array" (fun () ->
          expect @@ (list int) (Encode.jsonArray [||]) |> toEqual []);

      test "boolean" (fun () ->
          expect @@ list bool (parseOrRaise {| [true, false, true] |})
          |> toEqual [ true; false; true ]);
      test "float" (fun () ->
          expect @@ list float (parseOrRaise {| [1, 2, 3] |})
          |> toEqual [ 1.; 2.; 3. ]);
      test "int" (fun () ->
          expect @@ list int (parseOrRaise {| [1, 2, 3] |})
          |> toEqual [ 1; 2; 3 ]);
      test "string" (fun () ->
          expect @@ list string (parseOrRaise {| ["a", "b", "c"] |})
          |> toEqual [ "a"; "b"; "c" ]);
      test "nullAs" (fun () ->
          expect
          @@ list (nullAs Js.null) (parseOrRaise {| [null, null, null] |})
          |> toEqual [ Js.null; Js.null; Js.null ]);

      test "array int -> list boolean" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : bool list) =
                (list bool) (parseOrRaise {| [1, 2, 3] |})
              in
              fail "should throw")
          |> toEqual "expected a boolean but got 1\n\tin array at index 0");

      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : 'a list) =
              (list (fun _ -> raise Foo)) (Encode.list Encode.int [ 1 ])
            in
            fail "should throw"
          with Foo -> pass);

      Test.throws (list int)
        [ Bool; Float; Int; String; Null; Object; Char ]);

  describe "pair" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "heterogenous" (fun () ->
          expect @@ pair string int (parseOrRaise {| ["a", 3] |})
          |> toEqual ("a", 3));
      test "int int" (fun () ->
          expect @@ pair int int (parseOrRaise {| [4, 3] |})
          |> toEqual (4, 3));
      test "too small" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (pair int int) (parseOrRaise {| [4] |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array of length 2 but got [4]");
      test "too large" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (pair int int) (parseOrRaise {| [3, 4, 5] |})
              in
              fail "should throw")
          |> toEqual
               "expected tuple as array of length 2 but got [3, 4, 5]");
      test "bad type a" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (pair int int) (parseOrRaise {| ["3", 4] |})
              in
              fail "should throw")
          |> toEqual "expected an integer but got \"3\"\n\tin pair/tuple2");
      test "bad type b" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string * string) =
                (pair string string) (parseOrRaise {| ["3", 4] |})
              in
              fail "should throw")
          |> toEqual "expected a string but got 4\n\tin pair/tuple2");
      test "not array" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (pair int int) (parseOrRaise {| 4 |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array but got 4");
      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : int * int) =
              (pair (fun _ -> raise Foo) int) (parseOrRaise {| [4, 3] |})
            in
            fail "should throw"
          with Foo -> pass));

  describe "tuple2" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "heterogenous" (fun () ->
          expect @@ tuple2 string int (parseOrRaise {| ["a", 3] |})
          |> toEqual ("a", 3));
      test "too small" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (tuple2 int int) (parseOrRaise {| [4] |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array of length 2 but got [4]");
      test "too large" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (tuple2 int int) (parseOrRaise {| [3, 4, 5] |})
              in
              fail "should throw")
          |> toEqual
               "expected tuple as array of length 2 but got [3, 4, 5]");
      test "bad type a" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (tuple2 int int) (parseOrRaise {| ["3", 4] |})
              in
              fail "should throw")
          |> toEqual "expected an integer but got \"3\"\n\tin pair/tuple2");
      test "bad type b" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string * string) =
                (tuple2 string string) (parseOrRaise {| ["3", 4] |})
              in
              fail "should throw")
          |> toEqual "expected a string but got 4\n\tin pair/tuple2");
      test "not array" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int) =
                (tuple2 int int) (parseOrRaise {| 4 |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array but got 4");
      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : 'a * int) =
              (tuple2 (fun _ -> raise Foo) int)
                (parseOrRaise {| [4, 3] |})
            in
            fail "should throw"
          with Foo -> pass));

  describe "tuple3" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "heterogenous" (fun () ->
          expect
          @@ tuple3 string int float (parseOrRaise {| ["a", 3, 4.5] |})
          |> toEqual ("a", 3, 4.5));
      test "too small" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int) =
                (tuple3 int int int) (parseOrRaise {| [4] |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array of length 3 but got [4]");
      test "too large" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int) =
                (tuple3 int int int) (parseOrRaise {| [3, 4, 5, 6, 7] |})
              in
              fail "should throw")
          |> toEqual
               "expected tuple as array of length 3 but got [3, 4, 5, 6, \
                7]");
      test "bad type a" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int) =
                (tuple3 int int int) (parseOrRaise {| ["3", 4, 5] |})
              in
              fail "should throw")
          |> toEqual "expected an integer but got \"3\"\n\tin tuple3");
      test "bad type b" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string * string * string) =
                (tuple3 string string string)
                  (parseOrRaise {| ["3", 4, "5"] |})
              in
              fail "should throw")
          |> toEqual "expected a string but got 4\n\tin tuple3");
      test "not array" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int) =
                (tuple3 int int int) (parseOrRaise {| 4 |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array but got 4");
      test "not array" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int) =
                (tuple3 int int int) (parseOrRaise {| 4 |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array but got 4");
      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : int * int * int) =
              (tuple3 (fun _ -> raise Foo) int int)
                (parseOrRaise {| [4, 3, 5] |})
            in
            fail "should throw"
          with Foo -> pass));

  describe "tuple4" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "heterogenous" (fun () ->
          expect
          @@ tuple4 string int float bool
               (parseOrRaise {| ["a", 3, 4.5, true] |})
          |> toEqual ("a", 3, 4.5, true));
      test "too small" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int * int) =
                (tuple4 int int int int) (parseOrRaise {| [4] |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array of length 4 but got [4]");
      test "too large" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int * int) =
                (tuple4 int int int int)
                  (parseOrRaise {| [3, 4, 5, 6, 7, 8] |})
              in
              fail "should throw")
          |> toEqual
               "expected tuple as array of length 4 but got [3, 4, 5, 6, \
                7, 8]");
      test "bad type a" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int * int) =
                (tuple4 int int int int)
                  (parseOrRaise {| ["3", 4, 5, 6] |})
              in
              fail "should throw")
          |> toEqual "expected an integer but got \"3\"\n\tin tuple4");
      test "bad type b" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string * string * string * string) =
                (tuple4 string string string string)
                  (parseOrRaise {| ["3", 4, "5", "6"] |})
              in
              fail "should throw")
          |> toEqual "expected a string but got 4\n\tin tuple4");
      test "not array" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int * int * int * int) =
                (tuple4 int int int int) (parseOrRaise {| 4 |})
              in
              fail "should throw")
          |> toEqual "expected tuple as array but got 4");
      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : int * int * int * int) =
              (tuple4 (fun _ -> raise Foo) int int int)
                (parseOrRaise {| [4, 3, 5, 6] |})
            in
            fail "should throw"
          with Foo -> pass));

  describe "dict" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "object" (fun () ->
          expect @@ dict int (Encode.object_ [])
          |> toEqual (Js.Dict.empty ()));

      test "boolean" (fun () ->
          expect
          @@ dict bool (parseOrRaise {| { "a": true, "b": false } |})
          |> toEqual (Obj.magic [%obj { a = true; b = false }]));
      test "float" (fun () ->
          expect @@ dict float (parseOrRaise {| { "a": 1.2, "b": 2.3 } |})
          |> toEqual (Obj.magic [%obj { a = 1.2; b = 2.3 }]));
      test "int" (fun () ->
          expect @@ dict int (parseOrRaise {| { "a": 1, "b": 2 } |})
          |> toEqual (Obj.magic [%obj { a = 1; b = 2 }]));
      test "string" (fun () ->
          expect
          @@ dict string (parseOrRaise {| { "a": "x", "b": "y" } |})
          |> toEqual (Obj.magic [%obj { a = "x"; b = "y" }]));
      test "nullAs" (fun () ->
          expect
          @@ dict (nullAs Js.null)
               (parseOrRaise {| { "a": null, "b": null } |})
          |> toEqual (Obj.magic [%obj { a = Js.null; b = Js.null }]));
      test "null -> dict string" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string Js.Dict.t) =
                (dict string)
                  (parseOrRaise {| { "a": null, "b": null } |})
              in
              fail "should throw")
          |> toEqual
               "expected a string but got null\n\tin object at key 'a'");
      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : _ Js.Dict.t) =
              (dict (fun _ -> raise Foo)) (parseOrRaise {| { "a": 0 } |})
            in
            fail "should throw"
          with Foo -> pass);

      Test.throws (dict int)
        [ Bool; Float; Int; String; Null; Array; Char ]);

  describe "field" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "boolean" (fun () ->
          expect
          @@ field "b" bool (parseOrRaise {| { "a": true, "b": false } |})
          |> toEqual false);
      test "float" (fun () ->
          expect
          @@ field "b" float (parseOrRaise {| { "a": 1.2, "b": 2.3 } |})
          |> toEqual 2.3);
      test "int" (fun () ->
          expect @@ field "b" int (parseOrRaise {| { "a": 1, "b": 2 } |})
          |> toEqual 2);
      test "string" (fun () ->
          expect
          @@ field "b" string (parseOrRaise {| { "a": "x", "b": "y" } |})
          |> toEqual "y");
      test "nullAs" (fun () ->
          expect
          @@ field "b" (nullAs Js.null)
               (parseOrRaise {| { "a": null, "b": null } |})
          |> toEqual Js.null);
      test "missing key" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string) =
                (field "c" string)
                  (parseOrRaise {| { "a": null, "b": null } |})
              in
              fail "should throw")
          |> toEqual
               "expected object with field 'c' but got {\"a\": _, \"b\": \
                _}");
      test "decoder error" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : string) =
                (field "b" string)
                  (parseOrRaise {| { "a": null, "b": null } |})
              in
              fail "should throw")
          |> toEqual "expected a string but got null\n\tat field 'b'");

      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let _ =
              (field "a" (fun _ -> raise Foo))
                (parseOrRaise {| { "a": 0 } |})
            in
            fail "should throw"
          with Foo -> pass);

      Test.throws (field "foo" int)
        [ Bool; Float; Int; String; Null; Array; Object; Char ]);

  describe "at" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "boolean" (fun () ->
          expect
          @@ at [ "a"; "x"; "y" ] bool
               (parseOrRaise
                  {| {
             "a": { "x" : { "y" : false } },
             "b": false
           } |})
          |> toEqual false);
      test "nullAs" (fun () ->
          expect
          @@ at [ "a"; "x" ] (nullAs Js.null)
               (parseOrRaise
                  {| {
             "a": { "x" : null },
             "b": null
           } |})
          |> toEqual Js.null);

      test "missing key" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : 'a Js.null) =
                (at [ "a"; "y" ] (nullAs Js.null))
                  (parseOrRaise
                     {| {
             "a": { "x" : null },
             "b": null
           } |})
              in
              fail "should throw")
          |> toEqual
               "expected object with field 'y' but got {\"x\": _}\n\
                \tat field 'a'");
      test "decoder error" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : 'a Js.null) =
                (at [ "a"; "x"; "y" ] (nullAs Js.null))
                  (parseOrRaise
                     {| {
             "a": { "x" : { "y": "foo" } },
             "b": null
           } |})
              in
              fail "should throw")
          |> toEqual
               "expected null but got \"foo\"\n\
                \tat field 'y'\n\
                \tat field 'x'\n\
                \tat field 'a'");
      test "empty list of keys should raise Invalid_argument" (fun () ->
          try
            let (_ : int) = at [] int Js.Json.null in
            fail "should throw"
          with
          | Invalid_argument x
          when x == "Expected key_path to contain at least one element"
          ->
            pass);

      Test.throws
        (at [ "foo"; "bar" ] int)
        [ Bool; Float; Int; String; Null; Array; Object; Char ]);

  describe "optional" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "boolean -> int" (fun () ->
          expect @@ (optional int) (Encode.bool true) |> toEqual None);
      test "float -> int" (fun () ->
          expect @@ (optional int) (Encode.float 1.23) |> toEqual None);
      test "int -> int" (fun () ->
          expect @@ (optional int) (Encode.int 23) |> toEqual (Some 23));
      test "string -> int" (fun () ->
          expect @@ (optional int) (Encode.string "test") |> toEqual None);
      test "null -> int" (fun () ->
          expect @@ (optional int) Encode.null |> toEqual None);
      test "array -> int" (fun () ->
          expect @@ (optional int) (Encode.jsonArray [||]) |> toEqual None);
      test "object -> int" (fun () ->
          expect @@ (optional int) (Encode.object_ []) |> toEqual None);

      test "boolean -> boolean " (fun () ->
          expect @@ optional bool (Encode.bool true)
          |> toEqual (Some true));
      test "float -> float" (fun () ->
          expect @@ optional float (Encode.float 1.23)
          |> toEqual (Some 1.23));
      test "string -> string" (fun () ->
          expect @@ optional string (Encode.string "test")
          |> toEqual (Some "test"));
      test "null -> null" (fun () ->
          expect @@ optional (nullAs Js.null) Encode.null
          |> toEqual (Some Js.null));
      test "int -> boolean" (fun () ->
          expect @@ (optional bool) (Encode.int 1) |> toEqual None);

      test "optional field" (fun () ->
          expect
          @@ optional (field "x" int) (parseOrRaise {| { "x": 2} |})
          |> toEqual (Some 2));
      test "optional field - incorrect type" (fun () ->
          expect
          @@ optional (field "x" int) (parseOrRaise {| { "x": 2.3} |})
          |> toEqual None);
      test "optional field - no such field" (fun () ->
          expect
          @@ optional (field "y" int) (parseOrRaise {| { "x": 2} |})
          |> toEqual None);
      test "field optional" (fun () ->
          expect
          @@ field "x" (optional int) (parseOrRaise {| { "x": 2} |})
          |> toEqual (Some 2));
      test "field optional - incorrect type" (fun () ->
          expect
          @@ field "x" (optional int) (parseOrRaise {| { "x": 2.3} |})
          |> toEqual None);
      test "field optional - no such field" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int option) =
                (field "y" (optional int)) (parseOrRaise {| { "x": 2} |})
              in
              fail "should throw")
          |> toEqual "expected object with field 'y' but got {\"x\": _}");

      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : 'a option) =
              (optional (fun _ -> raise Foo)) Encode.null
            in
            fail "should throw"
          with Foo -> pass));

  describe "oneOf" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "object with field" (fun () ->
          expect
          @@ (oneOf [ int; field "x" int ]) (parseOrRaise {| { "x": 2} |})
          |> toEqual 2);
      test "int" (fun () ->
          expect @@ (oneOf [ int; field "x" int ]) (Encode.int 23)
          |> toEqual 23);

      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let _ = (oneOf [ (fun _ -> raise Foo) ]) Encode.null in
            fail "should throw"
          with Foo -> pass);

      Test.throws
        (oneOf [ int; field "x" int ])
        [ Bool; Float; String; Null; Array; Object; Char ]);

  describe "either" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "object with field" (fun () ->
          expect
          @@ (either int (field "x" int)) (parseOrRaise {| { "x": 2} |})
          |> toEqual 2);
      test "int" (fun () ->
          expect @@ (either int (field "x" int)) (Encode.int 23)
          |> toEqual 23);

      test "object as string in either" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let a = Encode.jsonDict (Js.Dict.empty ()) in
              let (_ : string) = either string string a in
              fail "should throw")
          |> toEqual
               "All decoders given to oneOf failed. Here are all the \
                errors: \n\
                - expected a string but got {}\n\
                - expected a string but got {}\n\
                And the JSON being decoded: {}");

      Test.throws
        (either int (field "x" int))
        [ Bool; Float; String; Null; Array; Object; Char ]);

  describe "withDefault" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "boolean" (fun () ->
          expect @@ (withDefault 0 int) (Encode.bool true) |> toEqual 0);
      test "float" (fun () ->
          expect @@ (withDefault 0 int) (Encode.float 1.23) |> toEqual 0);
      test "int" (fun () ->
          expect @@ (withDefault 0 int) (Encode.int 23) |> toEqual 23);
      test "string" (fun () ->
          expect @@ (withDefault 0 int) (Encode.string "test")
          |> toEqual 0);
      test "null" (fun () ->
          expect @@ (withDefault 0 int) Encode.null |> toEqual 0);
      test "array" (fun () ->
          expect @@ (withDefault 0 int) (Encode.jsonArray [||])
          |> toEqual 0);
      test "object" (fun () ->
          expect @@ (withDefault 0 int) (Encode.object_ []) |> toEqual 0);

      test "non-Of_json_error exceptions in decoder should pass through"
        (fun () ->
          try
            let (_ : int) =
              (withDefault 4 (fun _ -> raise Foo)) (Encode.int 0)
            in
            fail "should throw"
          with Foo -> pass));

  describe "map" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "int" (fun () ->
          expect @@ (int |> map (( + ) 2)) (Encode.int 23) |> toEqual 25);

      Test.throws
        (int |> map (( + ) 2))
        [ Bool; Float; String; Null; Array; Object; Char ]);

  describe "andThen" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "int -> int" (fun () ->
          expect @@ (int |> andThen (fun _ -> int)) (Encode.int 23)
          |> toEqual 23);

      test "int -> int andThen float" (fun () ->
          expect @@ (int |> andThen (fun _ -> float)) (Encode.int 23)
          |> toEqual 23.);
      test "int -> float andThen int" (fun () ->
          expect @@ (float |> andThen (fun _ -> int)) (Encode.int 23)
          |> toEqual 23);

      Test.throws ~name:"int andThen int "
        (int |> andThen (fun _ -> int))
        [ Bool; Float; String; Null; Array; Object; Char ];
      Test.throws ~name:"float andThen int "
        (float |> andThen (fun _ -> int))
        [ Float ];
      Test.throws ~name:"int to "
        (int |> andThen (fun _ -> float))
        [ Float ]);

  describe "composite expressions" (fun () ->
      let open Jsonkit in
      let open! Decode in
      test "dict array array int" (fun () ->
          expect
          @@ dict
               (array (array int))
               (parseOrRaise
                  {| { "a": [[1, 2], [3]], "b": [[4], [5, 6]] } |})
          |> toEqual
               (Obj.magic
                  [%obj
                    {
                      a = [| [| 1; 2 |]; [| 3 |] |];
                      b = [| [| 4 |]; [| 5; 6 |] |];
                    }]));
      test "dict array array int - heterogenous structure" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int array array Js.Dict.t) =
                (dict (array (array int)))
                  (parseOrRaise
                     {| { "a": [[1, 2], [true]], "b": [[4], [5, 6]] } |})
              in
              fail "should throw")
          |> toEqual
               "expected an integer but got true\n\
                \tin array at index 0\n\
                \tin array at index 1\n\
                \tin object at key 'a'");
      test "dict array array int - heterogenous structure 2" (fun () ->
          expect
          @@ wrap_exn (fun () ->
              let (_ : int array array Js.Dict.t) =
                (dict (array (array int)))
                  (parseOrRaise
                     {| { "a": [[1, 2], "foo"], "b": [[4], [5, 6]] } |})
              in
              fail "should throw")
          |> toEqual
               "expected an array but got \"foo\"\n\
                \tin array at index 1\n\
                \tin object at key 'a'");
      test "field" (fun () ->
          let json =
            parseOrRaise {| { "foo": [1, 2, 3], "bar": "baz" } |}
          in
          expect @@ (field "foo" (array int) json, field "bar" string json)
          |> toEqual ([| 1; 2; 3 |], "baz")))
