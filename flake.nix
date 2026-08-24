{
  description = "Reusable Github Actions";

  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";

    topiary-nu = {
      url = "github:ck3mp3r/flakes?dir=topiary-nu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {base-nixpkgs, ...}:
    base-nixpkgs.inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {system, ...}: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.topiary-nu.overlays.default
          ];
        };
      in {
        _module.args.pkgs = pkgs;

        devShells.default = pkgs.mkShellNoCC {
          name = "github-actions-dev";

          packages = with pkgs; [
            act
            alejandra
            statix
            topiary-nu
            nushell
            prek
          ];

          shellHook = ''
            echo "github-actions development shell"
            echo "Available commands:"
            echo "  act          - Run GitHub Actions locally"
            echo "  topiary      - Format Nushell code"
            echo "  prek install - Install git hook shims"
          '';
        };

        formatter = pkgs.alejandra;
      };
    };
}
