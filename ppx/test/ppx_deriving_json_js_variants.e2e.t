
  $ echo '(lang dune 3.11)
  > (using melange 0.1)' > dune-project

  $ echo '
  > (library
  >  (name lib)
  >  (modes melange)
  >  (modules main)
  >  (libraries jsonkit-melange)
  >  (flags :standard -w -20-37-69)
  >  (preprocess (pps melange.ppx jsonkit-melange.ppx)))
  > (melange.emit
  >  (alias js)
  >  (target output)
  >  (modules)
  >  (libraries lib)
  >  (module_systems commonjs))' > dune

  $ echo '
  > type sum = A [@@deriving json]
  > let json = sum_to_json A
  > ' >> main.ml

Can build without having to open Jsonkit.Primitives

  $ dune build @js
