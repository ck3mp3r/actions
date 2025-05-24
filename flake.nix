{
  description = "virtual environments";

  inputs.nixpkgs.url = "github:NixOs/nixpkgs/release-25.05";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    flake-utils,
    devshell,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowBroken = true;
        overlays = [devshell.overlays.default];
      };
    in {
      devShells.default = pkgs.devshell.mkShell {
        imports = [
          (pkgs.devshell.importTOML ./devshell.toml)
        ];
      };

      formatter = pkgs.alejandra;
    });
}
