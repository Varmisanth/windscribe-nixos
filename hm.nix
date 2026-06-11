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
    settings = lib.mkOption {
      type = lib.types.submodule { options = settingsLib.options; };
      default = { };
      description = ''
        Declarative Windscribe preferences overlay for this user.
        Replaces the NixOS module's settings rather than extending them.
        The patched App reads `~/.config/windscribe/settings.json` when it exists and `/etc/windscribe/settings.json` otherwise, never both.
        Declare settings on one level.
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
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs ? windscribe;
        message = "programs.windscribe requires the windscribe-nixos overlay applied to pkgs; importing nixosModules.windscribe or homeManagerModules.windscribe pulls it in automatically.";
      }
    ]
    ++ settingsLib.mkAssertions cfg.settings;
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
