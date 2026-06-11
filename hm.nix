{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.windscribe;
  settingsLib = import ./settings.nix { inherit lib pkgs; };
in
{
  options.programs.windscribe = {
    enable = lib.mkEnableOption "Windscribe VPN client";
    launchOnStartup = lib.mkOption {
      internal = true;
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Set by the NixOS module from `programs.windscribe.app`.
        This user's file replaces the system one, so the value would otherwise never reach the App.
        Configure auto-start through `programs.windscribe.app.autoStart` instead.
      '';
    };
    preferencesFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./windscribe-export.json";
      description = ''
        Path to a Windscribe Export JSON file for this user.
        Replaces the NixOS module's preferencesFile rather than extending it.
        The patched App reads `~/.config/windscribe/preferences.json` when it exists and `/etc/windscribe/preferences.json` otherwise, never both.
      '';
    };
    settings = lib.mkOption {
      type = lib.types.submodule { inherit (settingsLib) options; };
      default = { };
      description = ''
        Declarative Windscribe preferences overlay for this user.
        Replaces the NixOS module's settings rather than extending them.
        The patched App reads `~/.config/windscribe/settings.json` when it exists and `/etc/windscribe/settings.json` otherwise, never both.
        Declare settings on one level.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs ? windscribe;
        message = "programs.windscribe needs pkgs.windscribe. nixosModules.windscribe adds the overlay to the system pkgs; homeManagerModules.windscribe adds it to Home Manager's own pkgs, which home-manager.useGlobalPkgs replaces with the system ones — import nixosModules.windscribe in that case.";
      }
    ]
    ++ settingsLib.mkAssertions cfg.settings;
    warnings = settingsLib.mkWarnings cfg.settings;
    home.packages = [ pkgs.windscribe ];
    xdg.configFile =
      lib.optionalAttrs (!settingsLib.isEmpty cfg.settings) {
        "windscribe/settings.json".source = settingsLib.toJsonFile (
          cfg.settings // lib.optionalAttrs (cfg.launchOnStartup != null) { inherit (cfg) launchOnStartup; }
        );
      }
      // lib.optionalAttrs (cfg.preferencesFile != null) {
        "windscribe/preferences.json".source = cfg.preferencesFile;
      };
  };
}
