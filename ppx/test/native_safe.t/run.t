The native runtime is `Yojson.Safe`, so an integer literal that does not fit a
native int is kept as it was written instead of failing the whole parse.

  $ dune build ./main.exe

  $ dune exec ./main.exe -- '99999999999999999999' parse
  99999999999999999999

A payload is readable even when it carries such a literal in a field nobody
decodes. On `Yojson.Basic` this failed before any decoder ran.

  $ dune exec ./main.exe -- '{"sensor":"a","samples":3,"raw":99999999999999999999}' reading
  a has 3 samples

Decoding the literal itself as an int says what is wrong with it.

  $ dune exec ./main.exe -- '{"value":99999999999999999999}' as_int
  expected int, but the integer literal 99999999999999999999 does not fit a native int

As a float it decodes, with the precision a float has.

  $ dune exec ./main.exe -- '{"value":99999999999999999999}' as_float
  1e+20

`classify` reports the literal as it was written, so nothing is approximated
on the way out.

  $ dune exec ./main.exe -- '99999999999999999999' classify
  Intlit 99999999999999999999

  $ dune exec ./main.exe -- '42' classify
  Int 42

An int that fits is untouched.

  $ dune exec ./main.exe -- '{"value":42}' as_int
  42

`Yojson.Safe` reads yojson's own tuple and variant syntax, which is not JSON
and which `Yojson.Basic` rejected. It stays rejected, so moving to `Safe`
changes nothing but the integer literal above.

  $ dune exec ./main.exe -- '("a","b")' parse
  parse error: yojson's tuple and variant syntax is not JSON and is not supported

  $ dune exec ./main.exe -- '<"Foo">' parse
  parse error: yojson's tuple and variant syntax is not JSON and is not supported

Nested in an object or an array it is rejected just the same.

  $ dune exec ./main.exe -- '{"a":("x","y")}' parse
  parse error: yojson's tuple and variant syntax is not JSON and is not supported

  $ dune exec ./main.exe -- '[[[("deep","tuple")]]]' parse
  parse error: yojson's tuple and variant syntax is not JSON and is not supported

  $ dune exec ./main.exe -- '{"a":<"F":("p","q")>}' parse
  parse error: yojson's tuple and variant syntax is not JSON and is not supported
