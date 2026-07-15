  $ dune build ./prettify.exe
Uncomment to debug
$ ocamlopt -dsource _build/default/prettify.pp.ml > "$temp_file" 2>&1

Sum type: known cases round-trip; unknown cases are captured as
Jsonkit.unknown_variant_case with the full payload preserved.

  $ dune exec ./prettify.exe -- '"alpha"' sum
  got Alpha
  round-trip "alpha" -> "alpha"
  $ dune exec ./prettify.exe -- '["beta",7]' sum
  got Beta(7)
  round-trip ["beta",7] -> ["beta",7]
  $ dune exec ./prettify.exe -- '"gamma"' sum
  got Other(gamma,bare)
  round-trip "gamma" -> "gamma"
  $ dune exec ./prettify.exe -- '["gamma"]' sum
  got Other(gamma,[])
  round-trip ["gamma"] -> ["gamma"]
  $ dune exec ./prettify.exe -- '["gamma",42,"hi"]' sum
  got Other(gamma,[42;"hi"])
  round-trip ["gamma",42,"hi"] -> ["gamma",42,"hi"]

Polyvariant: same semantics, same argument type.

  $ dune exec ./prettify.exe -- '"alpha"' poly
  got Alpha
  round-trip "alpha" -> "alpha"
  $ dune exec ./prettify.exe -- '["beta",7]' poly
  got Beta(7)
  round-trip ["beta",7] -> ["beta",7]
  $ dune exec ./prettify.exe -- '"future"' poly
  got Other(future,bare)
  round-trip "future" -> "future"
  $ dune exec ./prettify.exe -- '["future"]' poly
  got Other(future,[])
  round-trip ["future"] -> ["future"]
  $ dune exec ./prettify.exe -- '["future",{"x":1}]' poly
  got Other(future,[{"x":1}])
  round-trip ["future",{"x":1}] -> ["future",{"x":1}]
