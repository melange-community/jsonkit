(lang dune 3.16)

(using melange 0.1)

(name jsonkit)

(generate_opam_files true)

(maintainers
 "Antonio Nuno Monteiro <anmonteiro@gmail.com>"
 "Javier Chávarri <javier.chavarri@gmail.com>"
 "Pedro Lisboa <pedrobslisboa@gmail.com>")

(license "LGPL-3.0-only" "MPL-2.0")

(homepage "https://github.com/melange-community/jsonkit/")

(bug_reports "https://github.com/melange-community/jsonkit/issues")

(source
 (github melange-community/jsonkit))

(package
 (name jsonkit-melange)
 (authors "glennsl" "Andrey Popp" "Pedro Lisboa")
 (synopsis
  "Compositional JSON encode/decode library and deriving PPX for Melange")
 (description
  "The Melange backend of jsonkit: converts JSON to typed OCaml values, where a JSON value is the Js.Json.t that JSON.parse returns, so no intermediate representation is built and the runtime stays small. It includes composable encoders and decoders and a deriving PPX that generates the conversions. The native backend is the jsonkit package: it exposes the same Jsonkit module, takes the same attributes and produces the same JSON, on top of Yojson.")
 (depends
  ocaml
  (melange
   (>= "4.0.0"))
  (melange-jest :with-test)
  (reason
   (and
    (>= "3.10.0")
    :with-test))
  (ppxlib
   (>= "0.38.0"))
  (opam-check-npm-deps
   (and
    (>= "4.1.0")
    :with-dev-setup
    (< :opam-version "2.6")))
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat
   (and
    (= "0.28.1")
    :with-dev-setup))))

(package
 (name jsonkit)
 (authors "Andrey Popp" "Pedro Lisboa")
 (synopsis
  "Compositional JSON encode/decode library and deriving PPX for OCaml")
 (description
  "The native backend of jsonkit: converts JSON to typed OCaml values on top of Yojson, where a JSON value is a Yojson.Basic.t. It includes encoders, decoders and a deriving PPX that generates the conversions. The Melange backend is the jsonkit-melange package: it exposes the same Jsonkit module, takes the same attributes and produces the same JSON, on top of Js.Json.t.")
 (depends
  (ocaml
   (>= "4.12"))
  (ppxlib
   (>= "0.38.0"))
  (yojson
   (>= "1.6.0"))))
