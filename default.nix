let
  overlay = final: _: { windscribe = import ./package.nix { pkgs = final; }; };
in
{
  homeManagerModules.windscribe =
    args@{ lib, ... }:
    let
      globalPkgs = (args.osConfig or { }).home-manager.useGlobalPkgs or false;
    in
    {
      imports = [ ./hm.nix ];
      nixpkgs.overlays = lib.mkIf (!globalPkgs) [ overlay ];
    };
  nixosModules.windscribe = {
    imports = [ ./os.nix ];
    nixpkgs.overlays = [ overlay ];
  };
  overlays.windscribe = overlay;
}
