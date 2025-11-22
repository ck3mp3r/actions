{
  description = "Reusable Github Actions";

  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {base-nixpkgs, ...}:
    base-nixpkgs.inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
      ];

      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        config,
        system,
        ...
      }: let
        pkgs = inputs.base-nixpkgs.legacyPackages.${system};
      in {
        _module.args.pkgs = pkgs;

        devenv.shells.default = {
          packages = with pkgs; [
            act
          ];

          scripts.format.exec = "nix fmt .";
          scripts.checks.exec = "nix flake check --impure";

          # Disable features we don't need
          containers = pkgs.lib.mkForce {};
        };

        formatter = pkgs.alejandra;
      };
    };
}
