{
  description = "virtual environments";

  inputs.nixpkgs.url = "github:NixOs/nixpkgs/23.11";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    flake-utils,
    devshell,
    nixpkgs,
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
