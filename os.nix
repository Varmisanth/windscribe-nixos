{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.windscribe;
  windscribe = pkgs.windscribe or (import ./package.nix { inherit pkgs; });
in
{
  options.services.windscribe = {
    enable = lib.mkEnableOption "Windscribe VPN client";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
  config = lib.mkIf cfg.enable {
    environment.etc = {
      "windscribe/platform" = {
        text = "linux_deb_x64";
      };
      "polkit-1/actions/com.windscribe.authhelper.policy" = {
        source = "${windscribe}/share/polkit-1/actions/com.windscribe.authhelper.policy";
      };
    };
    networking.networkmanager.enable = lib.mkDefault true;
    services.resolved.enable = lib.mkDefault true;
    systemd.services.windscribe-helper = {
      before = [ "network-pre.target" ];
      description = "Windscribe VPN helper daemon";
      path = with pkgs; [
        ethtool
        iproute2
        iptables
        iw
        kmod
        networkmanager
        sudo
      ];
      serviceConfig = {
        ExecStart = "${windscribe}/opt/windscribe/helper";
        Restart = "always";
        RestartSec = "5s";
        RuntimeDirectory = "windscribe";
        RuntimeDirectoryMode = "0770";
      };
      wantedBy = lib.optional cfg.autoStart "multi-user.target";
    };
    users.groups.windscribe = { };
    users.users = {
      windscribe = {
        group = "windscribe";
        isSystemUser = true;
        description = "Windscribe wstunnel runtime user";
      };
    }
    // lib.genAttrs cfg.users (_: {
      extraGroups = [ "windscribe" ];
    });
  };
}
