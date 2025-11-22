{
  description = "Reusable Github Actions";

  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    topiary-nu = {
      url = "github:ck3mp3r/flakes?dir=topiary-nu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {base-nixpkgs, ...}:
    base-nixpkgs.inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
      ];

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

        devenv.shells.default = {
          packages = with pkgs; [
            act
            topiary
            topiary-nu
          ];

          env = {
            TOPIARY_CONFIG_FILE = "${pkgs.topiary-nu}/languages.ncl";
            TOPIARY_LANGUAGE_DIR = "${pkgs.topiary-nu}/languages";
          };

          scripts.format.exec = "nix fmt .";
          scripts.checks.exec = "nix flake check --impure";

          git-hooks.hooks = {
            alejandra.enable = true;
            statix.enable = true;
            topiary = {
              enable = true;
              name = "topiary";
              entry = "${pkgs.topiary}/bin/topiary format";
              files = "\\.nu$";
              language = "system";
              pass_filenames = true;
            };
          };

          # Disable features we don't need
          containers = pkgs.lib.mkForce {};
        };

        formatter = pkgs.alejandra;
      };
    };
}
