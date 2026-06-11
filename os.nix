{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.programs.windscribe;
  windscribe = pkgs.windscribe;
  settingsLib = import ./settings.nix { inherit lib pkgs; };
  startupByNix = cfg.app.startupBy == "nix";
  launchOnStartup = cfg.app.autoStart && !startupByNix;
  declarativeSettings = settingsLib.toJsonFile (cfg.settings // { inherit launchOnStartup; });
  windscribeDesktop = pkgs.makeDesktopItem {
    categories = [ "Network" ];
    desktopName = "Windscribe";
    exec = "${lib.getExe windscribe} --autostart %F";
    extraConfig.SingleMainWindow = "true";
    icon = "Windscribe";
    name = "windscribe";
    startupWMClass = "Windscribe";
    type = "Application";
  };
in
{
  options.programs.windscribe = {
    enable = lib.mkEnableOption "Windscribe VPN client";
    app.startupBy = lib.mkOption {
      type = lib.types.enum [
        "app"
        "nix"
      ];
      default = "nix";
      description = ''
        Which mechanism starts the App with the session; `app.autoStart` decides whether it starts at all.
        Nix binds a systemd user service to the graphical session, leaving nothing behind in the home directory.
        App lets Windscribe write its own entry into `~/.config/autostart` at runtime.
        That entry needs something on the system to act on it — see `xdg.autostart.enable`.
      '';
    };
    app.autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether the App starts with the user session, by whichever mechanism `app.startupBy` selects.
        This lives here rather than in `settings` because under `"nix"` it governs a system-wide systemd unit.
        A per-user preference could not reach that unit.
      '';
    };
    installPackage = lib.mkOption {
      type = lib.types.bool;
      default = !(options ? home-manager) || cfg.users == [ ];
      description = ''
        Whether to install Windscribe system-wide.
        Defaults to false when Home Manager is set up and users is non-empty.
      '';
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users granted helper IPC access.
        When Home Manager is imported, listed users also receive the HM module.
      '';
    };
    settings = lib.mkOption {
      type = lib.types.submodule { options = settingsLib.options; };
      default = { };
      description = ''
        Declarative Windscribe preferences overlay.
        See settings.nix for the option set.
      '';
    };
    preferencesFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./windscribe-export.json";
      description = ''
        Path to a Windscribe Export JSON file — Preferences → Look & Feel → Export.
        Applied as the base state on every App start; the declarative settings overlay merges on top.
        Useful for bulk-migrating an existing in-App configuration without re-typing every option.
      '';
    };
  };
  config = lib.mkIf cfg.enable (
    {
      assertions =
        settingsLib.mkAssertions cfg.settings
        ++ lib.optionals (options ? home-manager) (
          lib.concatMap (
            user:
            let
              hmCfg = config.home-manager.users.${user}.programs.windscribe or { };
              hmSettings = hmCfg.settings or { };
            in
            lib.optional (!settingsLib.isEmpty cfg.settings && !settingsLib.isEmpty hmSettings) {
              assertion = false;
              message = ''programs.windscribe.settings is set in both nixosModules and homeManagerModules for user "${user}". Pick one location — the App reads the user file instead of the system one rather than merging the two, so the NixOS-level settings would be dropped entirely for this user.'';
            }
            ++ lib.optional (cfg.preferencesFile != null && (hmCfg.preferencesFile or null) != null) {
              assertion = false;
              message = ''programs.windscribe.preferencesFile is set in both nixosModules and homeManagerModules for user "${user}". Pick one location — the App reads the user file instead of the system one rather than merging the two, so the NixOS-level export would be dropped entirely for this user.'';
            }
          ) cfg.users
        );
      environment.etc = {
        "windscribe/autostart/windscribe.desktop" = {
          source = "${windscribeDesktop}/share/applications/windscribe.desktop";
        };
        "windscribe/platform" = {
          text = "linux_deb_x64";
        };
      }
      // lib.optionalAttrs (cfg.preferencesFile != null) {
        "windscribe/preferences.json" = {
          source = cfg.preferencesFile;
        };
      }
      // lib.optionalAttrs startupByNix {
        "windscribe/nix-autostart" = {
          text = "";
        };
      }
      // {
        "windscribe/settings.json" = {
          source = declarativeSettings;
        };
      };
      environment.systemPackages = lib.optional cfg.installPackage windscribe;
      system.activationScripts.windscribe = ''
        ${pkgs.procps}/bin/pkill -x Windscribe || true
        ${lib.optionalString startupByNix (
          lib.concatMapStringsSep "\n" (user: ''
            f=${config.users.users.${user}.home}/.config/autostart/windscribe.desktop
            if [ -L "$f" ] && [ "$(readlink "$f")" = "/etc/windscribe/autostart/windscribe.desktop" ]; then
              rm -f "$f"
            fi
          '') cfg.users
        )}
      '';
      systemd.services.windscribe-helper = {
        before = [ "network-pre.target" ];
        description = "Windscribe VPN helper daemon";
        path = with pkgs; [
          coreutils
          ethtool
          gawk
          iproute2
          iptables
          iw
          kmod
          procps
          util-linux
          windscribe.nmcli
        ];
        serviceConfig = {
          ExecStart = "${windscribe}/opt/windscribe/helper";
          Restart = "always";
          RestartSec = "5s";
          RuntimeDirectory = "windscribe";
          RuntimeDirectoryMode = "0770";
        };
        wantedBy = [ "multi-user.target" ];
      };
      systemd.user.services.windscribe = {
        description = "Windscribe";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = lib.getExe windscribe;
          Restart = "on-failure";
          RestartSec = "5s";
        };
        wantedBy = lib.optional (startupByNix && cfg.app.autoStart) "graphical-session.target";
      };
      users.groups.windscribe = { };
      users.users = {
        windscribe = {
          description = "Windscribe wstunnel runtime user";
          group = "windscribe";
          isSystemUser = true;
        };
      }
      // lib.genAttrs cfg.users (_: {
        extraGroups = [ "windscribe" ];
      });
      warnings =
        lib.optional (!startupByNix && cfg.app.autoStart && !config.xdg.autostart.enable) ''
          programs.windscribe.app.startupBy = "app" relies on the XDG autostart entry Windscribe writes into ~/.config/autostart, but xdg.autostart.enable is false, so systemd-xdg-autostart-generator is disabled and nothing will act on that entry unless your desktop implements the specification itself.
          Where nothing does, the App silently never starts with the session.
          Either set xdg.autostart.enable = true, or switch programs.windscribe.app.startupBy to "nix" and let the systemd user unit do it.
        ''
        ++
          lib.optional
            (
              cfg.installPackage
              && (options ? home-manager)
              && lib.any (u: u.programs.windscribe.enable or false) (
                lib.attrValues (config.home-manager.users or { })
              )
            )
            ''
              programs.windscribe.installPackage is true while Home Manager already installs Windscribe per-user.
              This is harmless but creates duplicate profile entries.
              Remove the manual installPackage assignment — the option resolves automatically from your configuration during module evaluation.
            '';
    }
    // lib.optionalAttrs (options ? home-manager) {
      home-manager.users = lib.genAttrs cfg.users (_: {
        imports = [ ./hm.nix ];
        programs.windscribe = {
          enable = true;
          inherit launchOnStartup;
        };
      });
    }
  );
}
