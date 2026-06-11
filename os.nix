{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.programs.windscribe;
  inherit (pkgs) windscribe;
  settingsLib = import ./settings.nix { inherit lib pkgs; };
  hmModule = (import ./.).homeManagerModules.windscribe;
  startupByNix = cfg.app.startupBy == "nix";
  launchOnStartup = cfg.app.autoStart && !startupByNix;
  homeOf = user: config.users.users.${user}.home;
  leftoverUsers = lib.filter (user: config.users.users ? ${user}) cfg.users;
  unlistedUsers = lib.filter (
    user:
    config.home-manager.users.${user}.programs.windscribe.enable or false && !lib.elem user cfg.users
  ) (lib.attrNames (config.home-manager.users or { }));
  autostartEntry = user: "${homeOf user}/.config/autostart/windscribe.desktop";
  dropAutostart = user: ''
    f=${lib.escapeShellArg (autostartEntry user)}
    if [ -L "$f" ] && [ "$(readlink "$f")" = "/etc/windscribe/autostart/windscribe.desktop" ]; then
      rm -f "$f"
    fi
  '';
  declarativeSettings = settingsLib.toJsonFile (cfg.settings // { inherit launchOnStartup; });
  resolvedEnable = [
    "services"
    "resolved"
    "enable"
  ];
  dnsBackends = {
    networkmanager = [
      [
        "networking"
        "networkmanager"
        "enable"
      ]
    ];
    resolvconf = [
      [
        "networking"
        "resolvconf"
        "enable"
      ]
      resolvedEnable
    ];
    systemd-resolved = [ resolvedEnable ];
  };
  dnsAssertion =
    scope: settings:
    let
      manager = settings.dnsManager or null;
      backends = dnsBackends.${manager};
      required = lib.concatMapStringsSep " and " lib.showOption backends;
      single = lib.length backends == 1;
      verb = if single then "is" else "are";
      target = if single then "it" else "one";
    in
    lib.optional (manager != null && dnsBackends ? ${manager}) {
      assertion = lib.any (option: lib.getAttrFromPath option config) backends;
      message = ''programs.windscribe.settings.dnsManager is "${manager}" ${scope}, but ${required} ${verb} false. The helper would fail to set the tunnel DNS. Enable ${target}, or set dnsManager to "auto".'';
    };
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
  userFiles =
    user:
    let
      files = config.home-manager.users.${user}.xdg.configFile;
    in
    lib.filter (file: file != null) [
      (files."windscribe/settings.json".source or null)
      (files."windscribe/preferences.json".source or null)
    ];
  appInputs = [
    declarativeSettings
  ]
  ++ lib.optional (cfg.preferencesFile != null) cfg.preferencesFile
  ++ lib.optionals (options ? home-manager) (lib.concatMap userFiles cfg.users);
in
{
  options.programs.windscribe = {
    enable = lib.mkEnableOption "Windscribe VPN client";

    app.autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether the App starts with the user session, by whichever mechanism `app.startupBy` selects.
        Off by default, since a VPN client that launches itself is a decision for you to make, not for this module.
        This lives here rather than in `settings` because under `"nix"` it governs a system-wide systemd unit.
        A per-user preference could not reach that unit.
      '';
    };

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

    installPackage = lib.mkOption {
      type = lib.types.bool;
      default = !(options ? home-manager) || cfg.users == [ ];
      description = ''
        Whether to install Windscribe system-wide.
        Defaults to false when Home Manager is set up and users is non-empty.
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

    purgeUserData = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether disabling the module also erases what the App left in each user's home.
        Windscribe stores its account and session under `~/.config/Windscribe`, which nothing else removes.
        Leaving this false keeps that state, so re-enabling the module finds the App still signed in.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.submodule { inherit (settingsLib) options; };
      default = { };
      description = ''
        Declarative Windscribe preferences overlay.
        See settings.nix for the option set.
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
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable (
      {
        assertions =
          settingsLib.mkAssertions cfg.settings
          ++ dnsAssertion "in nixosModules" cfg.settings
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
              ++ dnsAssertion ''for user "${user}" in homeManagerModules'' hmSettings
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
        }
        // lib.optionalAttrs startupByNix {
          "windscribe/nix-autostart" = {
            text = "";
          };
        }
        // {
          "windscribe/platform" = {
            text = "linux_deb_x64";
          };
        }
        // lib.optionalAttrs (cfg.preferencesFile != null) {
          "windscribe/preferences.json" = {
            source = cfg.preferencesFile;
          };
        }
        // {
          "windscribe/settings.json" = {
            source = declarativeSettings;
          };
        };
        environment.systemPackages = lib.optional cfg.installPackage windscribe;
        system.activationScripts.windscribe = lib.mkIf startupByNix (
          lib.concatLines (map dropAutostart cfg.users)
        );
        systemd.services.windscribe-helper = {
          wantedBy = [ "multi-user.target" ];
          description = "Windscribe VPN helper daemon";
          wants = [ "network-pre.target" ];
          before = [ "network-pre.target" ];
          serviceConfig = {
            RuntimeDirectory = "windscribe";
            RuntimeDirectoryMode = "0770";
            ExecStart = "${windscribe}/opt/windscribe/helper";
            RestartSec = "5s";
            Restart = "always";
          };
        };
        systemd.user.services.windscribe = {
          wantedBy = lib.optional (startupByNix && cfg.app.autoStart) "graphical-session.target";
          description = "Windscribe";
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          restartTriggers = appInputs;
          serviceConfig = {
            ExecStart = "${lib.getExe windscribe} --autostart";
            RestartSec = "5s";
            Restart = "on-failure";
          };
        };
        users.groups.windscribe = { };
        users.users = {
          windscribe = {
            description = "Windscribe wstunnel runtime user";
            isSystemUser = true;
            group = "windscribe";
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
          ++ lib.optional (options ? home-manager && unlistedUsers != [ ]) ''
            Home Manager enables programs.windscribe for ${lib.concatStringsSep ", " unlistedUsers}, but programs.windscribe.users does not list them.
            They lack the windscribe group, so the App cannot reach the helper.
            Add them to programs.windscribe.users; that also hands them the Home Manager module and turns installPackage off by default.
          ''
          ++
            lib.optional
              (
                cfg.installPackage
                && (options ? home-manager)
                && cfg.users != [ ]
                && lib.any (u: u.programs.windscribe.enable or false) (
                  lib.attrValues (config.home-manager.users or { })
                )
              )
              ''
                programs.windscribe.installPackage is true while Home Manager already installs Windscribe per-user.
                This is harmless but creates duplicate profile entries.
                Remove the manual installPackage assignment — the option resolves automatically from your configuration during module evaluation.
              ''
          ++ settingsLib.mkWarnings cfg.settings;
      }
      // lib.optionalAttrs (options ? home-manager) {
        home-manager.users = lib.genAttrs cfg.users (_: {
          imports = [ hmModule ];
          programs.windscribe = {
            enable = true;
            inherit launchOnStartup;
          };
        });
      }
    ))
    (lib.mkIf (!cfg.enable) {
      system.activationScripts.windscribe-cleanup = lib.concatLines (
        map (
          user:
          dropAutostart user
          + lib.optionalString cfg.purgeUserData ''
            rm -rf ${lib.escapeShellArg "${homeOf user}/.config/Windscribe"}
          ''
        ) leftoverUsers
      );
    })
  ];
}
