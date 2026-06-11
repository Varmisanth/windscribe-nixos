{
  description = "Windscribe VPN client packaged for NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    windscribe-qt.url = "github:NixOS/nixpkgs/nixos-24.11";
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
      windscribe-qt,
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
      windscribePkg =
        pkgs:
        import ./package.nix {
          inherit pkgs;
          qt6 = windscribe-qt.legacyPackages.${pkgs.stdenv.hostPlatform.system}.qt6;
          windscribeQt6ct = windscribe-qt.legacyPackages.${pkgs.stdenv.hostPlatform.system}.kdePackages.qt6ct;
        };
      windscribeOverlay = final: _: { windscribe = windscribePkg final; };
    in
    {
      checks = forAllSystems (system: {
        treefmt = treefmtEval.${system}.config.build.check self;
      });
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);
      homeManagerModules.windscribe = {
        imports = [ ./hm.nix ];
        nixpkgs.overlays = [ windscribeOverlay ];
      };
      nixosModules.windscribe = {
        imports = [ ./os.nix ];
        nixpkgs.overlays = [ windscribeOverlay ];
      };
      overlays.windscribe = windscribeOverlay;
      packages = forAllSystems (system: {
        default = windscribePkg nixpkgs.legacyPackages.${system};
        windscribe = self.packages.${system}.default;
      });
    };
}
