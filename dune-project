(lang dune 3.16)

(using melange 0.1)

(name jsonkit)

(generate_opam_files true)

(maintainers
 "Antonio Nuno Monteiro <anmonteiro@gmail.com>"
 "Javier Chávarri <javier.chavarri@gmail.com>")

(license "LGPL-3.0-only" "MPL-2.0")

(homepage "https://github.com/melange-community/jsonkit/")

(bug_reports "https://github.com/melange-community/jsonkit/issues")

(source
 (github melange-community/jsonkit))

(package
 (name jsonkit-melange)
 (authors "glennsl" "Andrey Popp")
 (synopsis "Compositional JSON encode/decode library and PPX for Melange")
 (description
  "Provides tools for converting JSON to typed OCaml values in Melange. It includes custom encoders, decoders, and a PPX for automating these conversions.")
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
  (opam-check-npm-deps :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat
   (and
    (= "0.28.1")
    :with-dev-setup))))

(package
 (name jsonkit)
 (authors "Andrey Popp")
 (synopsis "Compositional JSON encode/decode PPX for OCaml")
 (description
  "A PPX for OCaml that automates encoding and decoding JSON into typed values. It supports custom encoders and decoders, and integrates with Yojson")
 (depends
  (ocaml
   (>= "4.12"))
  (ppxlib
   (>= "0.38.0"))
  (yojson
   (>= "1.6.0"))))
