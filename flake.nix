{
  description = "Windscribe VPN client packaged for NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  nixConfig = {
    extra-substituters = [ "https://varmisanth.cachix.org" ];
    extra-trusted-public-keys = [
      "varmisanth.cachix.org-1:rt04yjDDJKDWe+h6B1XQWfdsSDUX6uks+9IKVBjn2d8="
    ];
  };
  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }
      );
      windscribeNixos = import ./.;
    in
    {
      checks = forAllSystems (system: {
        treefmt = treefmtEval.${system}.config.build.check self;
      });
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);
      inherit (windscribeNixos) homeManagerModules nixosModules overlays;
      packages = forAllSystems (system: {
        default = (nixpkgs.legacyPackages.${system}.extend windscribeNixos.overlays.windscribe).windscribe;
        windscribe = self.packages.${system}.default;
      });
    };
}
