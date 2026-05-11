{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.windscribe;
  windscribe = pkgs.windscribe or (import ./package.nix { inherit pkgs; });
in
{
  options.programs.windscribe = {
    enable = lib.mkEnableOption "Windscribe VPN client";
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ windscribe ];
  };
}
