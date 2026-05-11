{
  description = "Windscribe VPN client packaged for NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }
      );
    in
    {
      packages = forAllSystems (system: {
        default = import ./package.nix { pkgs = nixpkgs.legacyPackages.${system}; };
        windscribe = self.packages.${system}.default;
      });
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);
      checks = forAllSystems (system: {
        treefmt = treefmtEval.${system}.config.build.check self;
      });
      nixosModules.windscribe = ./os.nix;
      homeManagerModules.windscribe = ./hm.nix;
      overlays.default = final: _prev: {
        windscribe = import ./package.nix { pkgs = final; };
      };
    };
}
