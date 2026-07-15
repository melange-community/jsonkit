{
  description = "jsonkit Nix Flake";

  inputs.nixpkgs.url = "github:nix-ocaml/nix-overlays";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system:
        let
          pkgs = nixpkgs.legacyPackages.${system}.extend (self: super: {
            ocamlPackages = super.ocaml-ng.ocamlPackages_5_4;
          });
        in
        f pkgs);
    in
    {
      packages = forAllSystems (pkgs:
        let
          jsonkit = with pkgs.ocamlPackages; buildDunePackage {
            pname = "jsonkit";
            version = "dev";

            src =
              let fs = pkgs.lib.fileset; in
              fs.toSource {
                root = ./.;
                fileset = fs.unions [
                  ./dune-project
                  ./dune
                  ./jsonkit-melange.opam
                  ./jsonkit.opam
                  ./src
                  ./ppx
                ];
              };

            nativeBuildInputs = with pkgs.ocamlPackages; [ melange ];
            propagatedBuildInputs = with pkgs.ocamlPackages; [
              melange
              yojson
              ppxlib
            ];
          };
        in
        { inherit jsonkit; default = jsonkit; });
      devShells = forAllSystems (pkgs:
        let
          inherit (pkgs) nodejs_latest ocamlPackages system yarn;
          mkShell = { buildInputs ? [ ] }: pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.jsonkit ];
            nativeBuildInputs = [
              yarn
              nodejs_latest
            ] ++ (with ocamlPackages; [
              ocamlformat
              merlin
              melange-jest
              reason
              ocaml-lsp
            ]);
            inherit buildInputs;
          };
        in
        {
          default = mkShell { };
          release = mkShell {
            buildInputs = with pkgs; [ cacert curl ocamlPackages.dune-release git ];
          };
        }
      );
    };
}
