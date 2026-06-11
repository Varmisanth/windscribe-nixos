{ lib, pkgs }:
let
  enums = {
    dnsManager = {
      auto = 0;
      resolvconf = 1;
      systemd-resolved = 2;
      networkmanager = 3;
    };
    dnsPolicy = {
      os-default = 0;
      opendns = 1;
      cloudflare = 2;
      google = 3;
      controld = 4;
    };
    serverRouting = {
      auto = 0;
      regular = 1;
      alternative = 2;
    };
    protocolTweaks = {
      auto = 0;
      enabled = 1;
      disabled = 2;
    };
    ipStackEgress = {
      auto = 0;
      ipv4-only = 1;
    };
    firewallMode = {
      manual = 0;
      auto = 1;
      always-on = 2;
      always-on-plus = 3;
    };
    firewallWhen = {
      before-connection = 0;
      after-connection = 1;
    };
    connectedDnsType = {
      auto = 0;
      custom = 1;
      forced = 2;
      local = 3;
      controld = 4;
    };
    protocol = {
      ikev2 = 0;
      openvpn-udp = 1;
      openvpn-tcp = 2;
      stunnel = 3;
      wstunnel = 4;
      wireguard = 5;
    };
    proxyOption = {
      none = 0;
      autodetect = 1;
      http = 2;
      socks = 3;
    };
    appSkin = {
      alpha = 0;
      van-gogh = 1;
    };
    locationOrder = {
      geography = 0;
      alphabetical = 1;
      latency = 2;
    };
    trayIconColor = {
      white = 0;
      black = 1;
      os-theme = 2;
    };
    decoyTrafficVolume = {
      low = 0;
      medium = 1;
      high = 2;
    };
    proxySharingType = {
      http = 0;
      socks = 1;
    };
    soundNotificationType = {
      none = 0;
      bundled = 1;
      custom = 2;
    };
    backgroundType = {
      none = 0;
      country-flags = 1;
      custom = 2;
      bundled = 3;
    };
    aspectRatioMode = {
      stretch = 0;
      fill = 1;
      tile = 2;
    };
    splitTunnelingMode = {
      exclude = 0;
      include = 1;
    };
    splitTunnelingAppType = {
      user = 0;
      system = 1;
    };
    splitTunnelingNetworkRouteType = {
      ip = 0;
      hostname = 1;
    };
  };
  pruneNulls = lib.filterAttrs (_: v: v != null);
  onSet =
    f: v:
    if v == null then
      null
    else
      let
        kept = pruneNulls (f v);
      in
      if kept == { } then null else kept;
  mapEnum = e: v: if v == null then null else enums.${e}.${v};
  mapBool = v: if v == null then null else (if v then 1 else 0);
  b64 =
    str:
    builtins.readFile (
      pkgs.runCommand "b64" {
        inherit str;
        passAsFile = [ "str" ];
      } "base64 -w0 < $strPath > $out"
    );
  jsonToNix = {
    serverRoutingMethod = "serverRouting";
    protocolTweaksMethod = "protocolTweaks";
    isAllowLanTraffic = "allowLanTraffic";
    isKeepAliveEnabled = "keepAlive";
    isAntiCensorship = "apiAntiCensorship";
    isIgnoreSslErrors = "ignoreSslErrors";
    firewallSettings = "firewall";
    connectionSettings = "connection";
    connectedDnsInfo = "connectedDns";
    macAddrSpoofing = "macSpoofing";
    proxySettings = "proxy";
    decoyTrafficSettings = "decoyTraffic";
    favouriteLocations = "favoriteLocations";
    isAutoConnect = "autoConnect";
    isAutoSecureNetworks = "autoSecureNetworks";
    isMinimizeAndCloseToTray = "minimizeAndCloseToTray";
    isShowLocationHealth = "showLocationHealth";
    isShowNotifications = "showNotifications";
    isStartMinimized = "startMinimized";
    orderLocation = "locationOrder";
    trayIconColour = "trayIconColor";
  };
in
{
  options = {
    byApp = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "connection"
        "packetSize"
        "connectedDns"
        "macSpoofing"
        "proxy"
        "decoyTraffic"
        "splitTunneling"
      ];
      description = ''
        Option names to skip in the overlay.
        Windscribe fully owns these keys — use the same names as the Nix options below.
      '';
    };
    dnsManager = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "auto"
          "resolvconf"
          "systemd-resolved"
          "networkmanager"
        ]
      );
      default = null;
      example = "systemd-resolved";
      description = "System DNS manager Windscribe drives.";
    };
    dnsPolicy = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "os-default"
          "opendns"
          "cloudflare"
          "google"
          "controld"
        ]
      );
      default = null;
      example = "cloudflare";
      description = "DNS resolver for hostname lookups outside the tunnel.";
    };
    serverRouting = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "auto"
          "regular"
          "alternative"
        ]
      );
      default = null;
      example = "regular";
      description = ''Server pool selection: "auto" picks by latency, "regular" uses the standard fleet, "alternative" routes through alternate IPs to bypass service blocks.'';
    };
    protocolTweaks = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "auto"
          "enabled"
          "disabled"
        ]
      );
      default = null;
      example = "enabled";
      description = ''AmneziaWG obfuscation tri-state for the App's Anti-censorship toggle: "auto" picks a server-suggested preset, "enabled" forces amneziawgPreset, "disabled" falls back to plain WireGuard.'';
    };
    ipStackEgress = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "auto"
          "ipv4-only"
        ]
      );
      default = null;
      example = "ipv4-only";
      description = ''Egress IP stack for WireGuard connections: "auto" keeps the server-offered dual stack, "ipv4-only" drops IPv6 inside the tunnel.'';
    };
    allowLanTraffic = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to allow access to local services and printers while connected.";
    };
    keepAlive = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to periodically ping the server to keep idle connections alive.";
    };
    apiAntiCensorship = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to obfuscate API traffic to bypass deep packet inspection.";
    };
    ignoreSslErrors = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to ignore SSL certificate validation errors.";
    };
    robert = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            malware = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''Whether to block known malware domains; shown as "Malware" in the App.'';
            };
            ads = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''Whether to block ads and trackers; shown as "Ad + Trackers" in the App.'';
            };
            social = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = false;
              description = ''Whether to block social networks; shown as "Social Networks" in the App.'';
            };
            porn = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''Whether to block adult content; shown as "Porn" in the App.'';
            };
            gambling = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''Whether to block gambling sites; shown as "Gambling" in the App.'';
            };
            fakenews = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''Whether to block known fake-news and clickbait outlets; shown as "Clickbait" in the App.'';
            };
            competitors = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''Whether to block other VPN providers; shown as "Other VPNs" in the App.'';
            };
            cryptominers = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''Whether to block in-browser cryptocurrency miners; shown as "Crypto" in the App.'';
            };
          };
        }
      );
      default = null;
      example = {
        malware = true;
        ads = true;
        social = false;
        porn = true;
        gambling = true;
        fakenews = true;
        competitors = true;
        cryptominers = true;
      };
      description = ''
        Account-scoped R.O.B.E.R.T. content filter overrides.
        The App pulls the filter list from the server on login; each filter present here is set to the chosen state via setRobertFilter once the list arrives.
      '';
    };
    language = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "en"
          "ar"
          "be"
          "cs"
          "de"
          "el"
          "es"
          "fa"
          "fr"
          "hi"
          "id"
          "it"
          "ja"
          "ko"
          "pl"
          "pt"
          "ru"
          "sk"
          "tr"
          "uk"
          "vi"
          "zh-CN"
          "zh-TW"
        ]
      );
      default = null;
      example = "en";
      description = "UI language code.";
    };
    amneziawgPreset = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "A - No Junk Russia Primary"
          "B - No Junk Russia Alt"
          "C - With Junk Russia Primary"
          "D - With Junk Russia Alt"
          "E - Baseline No Junk"
          "F - Baseline With Junk"
          "G - Popular Website with Junk"
          "H - Iran 26 May 2026"
          "I - Iran Legacy"
        ]
      );
      default = null;
      example = "E - Baseline No Junk";
      description = ''AmneziaWG preset chosen when `protocolTweaks = "enabled";` ignored otherwise.'';
    };
    customOvpnConfigsPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/etc/windscribe-ovpn";
      description = "Directory holding user-provided OpenVPN configs.";
    };
    advancedParameters = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      example = ''
        tunnel-test-timeout 30
      '';
      description = ''
        Free-form Advanced Parameters injected into generated OpenVPN/WireGuard configs.
        Mirrors the App's Preferences → Advanced → Advanced Parameters text field.
        Refer to utils/extraconfig.cpp for Windscribe-specific directives; vanilla OpenVPN/WireGuard options pass through to the generated config.
      '';
    };
    favoriteLocations = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf (lib.types.attrsOf lib.types.anything));
      default = null;
      example = [
        {
          type = 0;
          id = 110;
          city = "Bunker 42";
        }
      ];
      description = ''
        Server-assigned location IDs starred as favourites.
        Mirrors what the App's location list ★ button stores and what Export writes under "favouriteLocations".
        Each entry needs type, id, and city — entries missing any of the three are silently dropped at load.
      '';
    };
    networkPreferredProtocols = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
      default = null;
      example = {
        "SG9tZSBXaUZp" = {
          protocol = 5;
          port = 443;
          isAutomatic = false;
        };
      };
      description = ''
        Per-network preferred protocol overrides.
        Mirrors the App's Network Options → Preferred Protocol toggle, persisted per Wi-Fi/ethernet network name.
        Best seeded from an Export rather than hand-written: keys are base64-encoded network names, protocol is an int enum.
      '';
    };
    persistentState = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
      default = null;
      example = {
        networks = [
          {
            networkOrSsid = "SG9tZSBXaUZp";
            trustType = 0;
          }
        ];
      };
      description = ''
        Persistent App state — Secured/Unsecured network whitelist, last-known protocol, etc.
        Mirrors the "persistentState" object the App writes during Export.
        Best seeded from an Export rather than hand-written: networkOrSsid is base64-encoded, trustType is an int enum.
      '';
    };
    renamedLocations = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
      default = null;
      example = {
        locations = [
          {
            id = 27;
            country = "Wurstheim";
            cities = [
              {
                id = 110;
                name = "Bunker 42";
                nickname = "Cold War Chic";
              }
            ];
          }
        ];
      };
      description = ''
        Per-location display name overrides.
        Mirrors what Preferences → Look & Feel → Rename Locations → Import accepts.
        Export from the App once to seed the structure.
        A location needs its server-assigned numeric id plus `country`; a city needs its own id plus `name` and `nickname`.
        Give a city both keys whenever you list it: the App assigns each unconditionally.
        A key left out therefore arrives as an empty string and erases the rename stored for that city.
      '';
    };
    firewall = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            mode = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "manual"
                  "auto"
                  "always-on"
                  "always-on-plus"
                ]
              );
              default = null;
              example = "always-on";
              description = ''Firewall activation: "manual" toggled from the App, "auto" follows connection state, "always-on" stays on even disconnected, "always-on-plus" also blocks the Windscribe API when disconnected.'';
            };
            when = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "before-connection"
                  "after-connection"
                ]
              );
              default = null;
              example = "before-connection";
              description = "Firewall rule install order relative to the tunnel.";
            };
          };
        }
      );
      default = null;
      example = {
        mode = "always-on";
        when = "before-connection";
      };
      description = "Kill-switch that blocks all non-Windscribe traffic outside the tunnel.";
    };
    connection = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            isAutomatic = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = false;
              description = "Whether to pick the protocol automatically.";
            };
            protocol = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "ikev2"
                  "openvpn-udp"
                  "openvpn-tcp"
                  "stunnel"
                  "wstunnel"
                  "wireguard"
                ]
              );
              default = null;
              example = "wireguard";
              description = "Manual VPN protocol when `isAutomatic` is false.";
            };
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              example = 443;
              description = "Port used by the selected protocol.";
            };
          };
        }
      );
      default = null;
      example = {
        isAutomatic = false;
        protocol = "wireguard";
        port = 443;
      };
      description = "VPN protocol and port selection.";
    };
    packetSize = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            isAutomatic = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = false;
              description = "Whether to determine the MTU automatically.";
            };
            mtu = lib.mkOption {
              type = lib.types.nullOr (lib.types.ints.between 68 65535);
              default = null;
              example = 1470;
              description = "Manual MTU when `isAutomatic` is false.";
            };
          };
        }
      );
      default = null;
      example = {
        isAutomatic = false;
        mtu = 1500;
      };
      description = "Packet size for the tunnel.";
    };
    connectedDns = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "auto"
                  "custom"
                  "forced"
                  "local"
                  "controld"
                ]
              );
              default = null;
              example = "custom";
              description = "Source of the resolver advertised inside the tunnel.";
            };
            upStream1 = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "1.1.1.1";
              description = "Primary upstream resolver as IP, hostname or DoH/DoT URL.";
            };
            upStream2 = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "1.0.0.1";
              description = "Secondary upstream resolver as IP, hostname or DoH/DoT URL.";
            };
            isSplitDns = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = "Whether to resolve listed hostnames upstream; the rest use the tunnel's default resolver.";
            };
            hostnames = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
              example = [
                "example.com"
                "internal.lan"
              ];
              description = "Hostnames affected by split DNS.";
            };
            controldApiKey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "ctrld-xxxxxxxxxxxxxxxx";
              description = "Control D API key when type is controld.";
            };
          };
        }
      );
      default = null;
      example = {
        type = "custom";
        upStream1 = "1.1.1.1";
        upStream2 = "1.0.0.1";
      };
      description = "DNS resolver used inside the tunnel.";
    };
    macSpoofing = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            isEnabled = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = "Whether to overwrite the physical MAC address.";
            };
            macAddress = lib.mkOption {
              type = lib.types.nullOr (lib.types.strMatching "^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$");
              default = null;
              example = "DE:AD:BE:EF:00:00";
              description = "MAC address in colon notation.";
            };
            isAutoRotate = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = "Whether to rotate the spoofed MAC on each network change.";
            };
          };
        }
      );
      default = null;
      example = {
        isEnabled = true;
        macAddress = "DE:AD:BE:EF:00:00";
        isAutoRotate = true;
      };
      description = "MAC address spoofing for the active interface.";
    };
    proxy = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            option = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "none"
                  "autodetect"
                  "http"
                  "socks"
                ]
              );
              default = null;
              example = "http";
              description = "LAN proxy mode for TCP connections to Windscribe servers.";
            };
            address = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "127.0.0.1";
              description = "Proxy hostname or IP.";
            };
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              example = 8080;
              description = "Proxy port.";
            };
            username = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "alice";
              description = "Proxy authentication username.";
            };
            password = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "secret";
              description = "Proxy authentication password.";
            };
          };
        }
      );
      default = null;
      example = {
        option = "http";
        address = "127.0.0.1";
        port = 8080;
      };
      description = "Outbound LAN proxy used to reach Windscribe servers.";
    };
    decoyTraffic = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            isEnabled = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = "Whether to generate background traffic to defeat traffic correlation.";
            };
            volume = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "low"
                  "medium"
                  "high"
                ]
              );
              default = null;
              example = "low";
              description = "Volume of decoy traffic generated.";
            };
          };
        }
      );
      default = null;
      example = {
        isEnabled = true;
        volume = "low";
      };
      description = "Experimental decoy traffic generator.";
    };
    shareProxyGateway = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            isEnabled = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = "Whether to share this machine as a proxy gateway on the LAN.";
            };
            proxySharingMode = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "http"
                  "socks"
                ]
              );
              default = null;
              example = "http";
              description = "Protocol exposed by the shared gateway.";
            };
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              example = 8080;
              description = "Port the shared gateway listens on.";
            };
            whileConnected = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = "Whether to keep sharing only while connected to the VPN.";
            };
            requireAuth = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              example = true;
              description = ''
                Whether to require authentication from clients of the shared gateway.
                The App generates credentials on first enable when `username` and `password` are left unset.
                Set this explicitly whenever the gateway is enabled.
                A missing key next to `isEnabled = true` reads to the App as a config predating gateway auth, and it turns authentication off.
              '';
            };
            username = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "alice";
              description = "Gateway authentication username when `requireAuth` is true.";
            };
            password = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "secret";
              description = "Gateway authentication password when `requireAuth` is true.";
            };
          };
        }
      );
      default = null;
      example = {
        isEnabled = true;
        proxySharingMode = "http";
        port = 8080;
        whileConnected = true;
      };
      description = "LAN-side proxy gateway sharing.";
    };
    soundSettings = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            disconnectedSoundType = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "none"
                  "bundled"
                  "custom"
                ]
              );
              default = null;
              example = "custom";
              description = "Sound played on disconnect.";
            };
            disconnectedSoundPath = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/etc/windscribe/disconnect.wav";
              description = ''
                Path to the custom disconnect sound file.
                Accepted formats: `.wav`, `.mp3`.
              '';
            };
            connectedSoundType = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "none"
                  "bundled"
                  "custom"
                ]
              );
              default = null;
              example = "custom";
              description = "Sound played on connect.";
            };
            connectedSoundPath = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/etc/windscribe/connect.wav";
              description = ''
                Path to the custom connect sound file.
                Accepted formats: `.wav`, `.mp3`.
              '';
            };
          };
        }
      );
      default = null;
      example = {
        disconnectedSoundType = "custom";
        disconnectedSoundPath = "/etc/windscribe/disconnect.wav";
        connectedSoundType = "custom";
        connectedSoundPath = "/etc/windscribe/connect.wav";
      };
      description = "Notification sounds for connection events.";
    };
    backgroundSettings = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            disconnectedBackgroundType = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "none"
                  "country-flags"
                  "custom"
                  "bundled"
                ]
              );
              default = null;
              example = "custom";
              description = ''Background source when disconnected: "none" shows nothing, "country-flags" shows the location flag, "custom" uses backgroundImageDisconnected, "bundled" uses an App-bundled image.'';
            };
            connectedBackgroundType = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "none"
                  "country-flags"
                  "custom"
                  "bundled"
                ]
              );
              default = null;
              example = "custom";
              description = ''Background source when connected: "none" shows nothing, "country-flags" shows the location flag, "custom" uses backgroundImageConnected, "bundled" uses an App-bundled image.'';
            };
            aspectRatioMode = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "stretch"
                  "fill"
                  "tile"
                ]
              );
              default = null;
              example = "fill";
              description = ''How the background image fits the window: "stretch" distorts to fit, "fill" crops to cover, "tile" repeats the image.'';
            };
            backgroundImageDisconnected = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/etc/windscribe/bg-disconnected.jpg";
              description = ''
                Path to the custom disconnected background image.
                Accepted formats: `.png`, `.jpg`, `.gif`.
              '';
            };
            backgroundImageConnected = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/etc/windscribe/bg-connected.jpg";
              description = ''
                Path to the custom connected background image.
                Accepted formats: `.png`, `.jpg`, `.gif`.
              '';
            };
          };
        }
      );
      default = null;
      example = {
        disconnectedBackgroundType = "custom";
        connectedBackgroundType = "custom";
        aspectRatioMode = "fill";
        backgroundImageDisconnected = "/etc/windscribe/bg-disconnected.jpg";
        backgroundImageConnected = "/etc/windscribe/bg-connected.jpg";
      };
      description = "App background image selection.";
    };
    splitTunneling = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            settings = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    active = lib.mkOption {
                      type = lib.types.nullOr lib.types.bool;
                      default = null;
                      example = true;
                      description = "Whether split tunneling is on.";
                    };
                    mode = lib.mkOption {
                      type = lib.types.nullOr (
                        lib.types.enum [
                          "exclude"
                          "include"
                        ]
                      );
                      default = null;
                      example = "exclude";
                      description = "Whether listed apps and routes are excluded from or included in the tunnel.";
                    };
                  };
                }
              );
              default = null;
              example = {
                active = true;
                mode = "exclude";
              };
              description = "Split tunneling toggle and mode.";
            };
            apps = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      active = lib.mkOption {
                        type = lib.types.nullOr lib.types.bool;
                        default = null;
                        example = true;
                        description = "Whether this app is active in the routing list.";
                      };
                      fullName = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        example = lib.literalExpression "lib.getExe pkgs.firefox";
                        description = "Filesystem path of the executable.";
                      };
                      name = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        example = "Firefox";
                        description = "Display name shown in the App.";
                      };
                      icon = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        example = lib.literalExpression ''"''${pkgs.firefox}/share/icons/hicolor/128x128/apps/firefox.png"'';
                        description = "Filesystem path of the icon.";
                      };
                      type = lib.mkOption {
                        type = lib.types.nullOr (
                          lib.types.enum [
                            "user"
                            "system"
                          ]
                        );
                        default = null;
                        example = "user";
                        description = ''Entry source: "user" added manually with a custom path, "system" auto-discovered from installed programs.'';
                      };
                    };
                  }
                )
              );
              default = null;
              example = lib.literalExpression ''
                [
                  {
                    active = true;
                    fullName = lib.getExe pkgs.firefox;
                    name = "Firefox";
                    type = "user";
                  }
                ]
              '';
              description = "Apps routed under the split-tunnel policy.";
            };
            networkRoutes = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      type = lib.mkOption {
                        type = lib.types.nullOr (
                          lib.types.enum [
                            "ip"
                            "hostname"
                          ]
                        );
                        default = null;
                        example = "ip";
                        description = "Whether the route is an IP CIDR or a hostname.";
                      };
                      name = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        example = "10.0.0.0/24";
                        description = "Route entry as IP CIDR or as a hostname.";
                      };
                      active = lib.mkOption {
                        type = lib.types.nullOr lib.types.bool;
                        default = null;
                        example = true;
                        description = "Whether this route is active.";
                      };
                    };
                  }
                )
              );
              default = null;
              example = [
                {
                  type = "ip";
                  name = "10.0.0.0/24";
                  active = true;
                }
              ];
              description = "Network routes under the split-tunnel policy.";
            };
          };
        }
      );
      default = null;
      example = lib.literalExpression ''
        {
          settings = {
            active = true;
            mode = "exclude";
          };
          apps = [
            {
              active = true;
              fullName = lib.getExe pkgs.firefox;
              name = "Firefox";
              type = "user";
            }
          ];
          networkRoutes = [
            {
              type = "ip";
              name = "10.0.0.0/24";
              active = true;
            }
          ];
        }
      '';
      description = "Per-app and per-route tunnel inclusion.";
    };
    appSkin = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "alpha"
          "van-gogh"
        ]
      );
      default = null;
      example = "van-gogh";
      description = ''App theme: "alpha" is the original design, "van-gogh" is the redesigned look.'';
    };
    autoConnect = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to reconnect to the last location when the App launches or joins a network.";
    };
    autoSecureNetworks = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to mark new networks as Secured by default.";
    };
    minimizeAndCloseToTray = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to send the App to the system tray on close instead of quitting.";
    };
    showLocationHealth = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to display per-location health bars.";
    };
    showNotifications = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to show system notifications for connection events.";
    };
    startMinimized = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      example = true;
      description = "Whether to launch the App in a minimized state.";
    };
    locationOrder = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "geography"
          "alphabetical"
          "latency"
        ]
      );
      default = null;
      example = "latency";
      description = ''Location list sorting: by "geography", "alphabetical" name, or by "latency".'';
    };
    trayIconColor = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "white"
          "black"
          "os-theme"
        ]
      );
      default = null;
      example = "os-theme";
      description = ''Tray icon colour: "white" renders light, "black" renders dark, "os-theme" follows the system theme.'';
    };
  };
  toJsonFile =
    s:
    let
      mkFirewall = onSet (v: {
        mode = mapEnum "firewallMode" v.mode;
        when = mapEnum "firewallWhen" v.when;
      });
      mkConnection = onSet (v: {
        protocol = mapEnum "protocol" v.protocol;
        inherit (v) isAutomatic port;
      });
      mkPacketSize = onSet (v: {
        inherit (v) isAutomatic mtu;
      });
      mkConnectedDns = onSet (v: {
        type = mapEnum "connectedDnsType" v.type;
        controldApiKey = if v.controldApiKey == null then null else b64 v.controldApiKey;
        inherit (v)
          upStream1
          upStream2
          isSplitDns
          hostnames
          ;
      });
      mkMacSpoofing = onSet (v: {
        inherit (v) isEnabled macAddress isAutoRotate;
      });
      mkProxy = onSet (v: {
        option = mapEnum "proxyOption" v.option;
        password = if v.password == null then null else b64 v.password;
        inherit (v) address port username;
      });
      mkDecoy = onSet (v: {
        volume = mapEnum "decoyTrafficVolume" v.volume;
        inherit (v) isEnabled;
      });
      mkShareProxyGateway = onSet (v: {
        proxySharingMode = mapEnum "proxySharingType" v.proxySharingMode;
        inherit (v)
          isEnabled
          port
          whileConnected
          requireAuth
          username
          password
          ;
      });
      mkSound = onSet (v: {
        disconnectedSoundType = mapEnum "soundNotificationType" v.disconnectedSoundType;
        connectedSoundType = mapEnum "soundNotificationType" v.connectedSoundType;
        inherit (v) disconnectedSoundPath connectedSoundPath;
      });
      mkAdvancedParams = v: if v == null || v == "" then null else { fileContents = b64 v; };
      mkBackground = onSet (v: {
        disconnectedBackgroundType = mapEnum "backgroundType" v.disconnectedBackgroundType;
        connectedBackgroundType = mapEnum "backgroundType" v.connectedBackgroundType;
        aspectRatioMode = mapEnum "aspectRatioMode" v.aspectRatioMode;
        inherit (v) backgroundImageDisconnected backgroundImageConnected;
      });
      mkRobert = onSet (v: lib.mapAttrs (_: mapBool) v);
      mkSplitTunneling = onSet (v: {
        settings = onSet (t: {
          mode = mapEnum "splitTunnelingMode" t.mode;
          inherit (t) active;
        }) v.settings;
        apps =
          if v.apps == null then
            null
          else
            map (
              a:
              pruneNulls {
                type = mapEnum "splitTunnelingAppType" a.type;
                inherit (a)
                  active
                  fullName
                  name
                  icon
                  ;
              }
            ) v.apps;
        networkRoutes =
          if v.networkRoutes == null then
            null
          else
            map (
              r:
              pruneNulls {
                type = mapEnum "splitTunnelingNetworkRouteType" r.type;
                inherit (r) name active;
              }
            ) v.networkRoutes;
      });
      raw = pruneNulls {
        dnsManager = mapEnum "dnsManager" s.dnsManager;
        dnsPolicy = mapEnum "dnsPolicy" s.dnsPolicy;
        serverRoutingMethod = mapEnum "serverRouting" s.serverRouting;
        protocolTweaksMethod = mapEnum "protocolTweaks" s.protocolTweaks;
        ipStackEgress = mapEnum "ipStackEgress" s.ipStackEgress;
        isAllowLanTraffic = s.allowLanTraffic;
        isKeepAliveEnabled = s.keepAlive;
        isAntiCensorship = s.apiAntiCensorship;
        isIgnoreSslErrors = s.ignoreSslErrors;
        inherit (s) amneziawgPreset language;
        customOvpnConfigsPath =
          if s.customOvpnConfigsPath == null then null else b64 (toString s.customOvpnConfigsPath);
        firewallSettings = mkFirewall s.firewall;
        connectionSettings = mkConnection s.connection;
        packetSize = mkPacketSize s.packetSize;
        connectedDnsInfo = mkConnectedDns s.connectedDns;
        macAddrSpoofing = mkMacSpoofing s.macSpoofing;
        proxySettings = mkProxy s.proxy;
        decoyTrafficSettings = mkDecoy s.decoyTraffic;
        shareProxyGateway = mkShareProxyGateway s.shareProxyGateway;
        soundSettings = mkSound s.soundSettings;
        advancedParameters = mkAdvancedParams s.advancedParameters;
        backgroundSettings = mkBackground s.backgroundSettings;
        favouriteLocations = s.favoriteLocations;
        networkPreferredProtocols = s.networkPreferredProtocols;
        persistentState = s.persistentState;
        renamedLocations = s.renamedLocations;
        robert = mkRobert s.robert;
        splitTunneling = mkSplitTunneling s.splitTunneling;
        appSkin = mapEnum "appSkin" s.appSkin;
        isAutoConnect = s.autoConnect;
        isAutoSecureNetworks = s.autoSecureNetworks;
        isLaunchOnStartup = s.launchOnStartup or null;
        isMinimizeAndCloseToTray = s.minimizeAndCloseToTray;
        isShowLocationHealth = s.showLocationHealth;
        isShowNotifications = s.showNotifications;
        isStartMinimized = s.startMinimized;
        orderLocation = mapEnum "locationOrder" s.locationOrder;
        trayIconColour = mapEnum "trayIconColor" s.trayIconColor;
      };
    in
    (pkgs.formats.json { }).generate "windscribe-settings.json" (
      lib.filterAttrs (k: _: !(lib.elem (jsonToNix.${k} or k) s.byApp)) raw
    );
  isEmpty = s: (lib.filterAttrs (k: v: k != "byApp" && v != null) s) == { };
  mkAssertions =
    s:
    let
      need = path: condStr: "programs.windscribe.settings.${path} must be set when ${condStr}.";
      anySet = v: fields: lib.any (f: v.${f} != null) fields;
      orCond = lib.concatMapStringsSep " or ";
      completes =
        path: primary: dependents: v:
        lib.optional (v != null && anySet v dependents) {
          assertion = v.${primary} != null;
          message = need "${path}.${primary}" (orCond (f: "${path}.${f} is set") dependents);
        };
    in
    lib.optional (s.byApp != [ ]) (
      let
        unknown = lib.subtractLists (lib.remove "byApp" (builtins.attrNames s)) s.byApp;
      in
      {
        assertion = unknown == [ ];
        message = "programs.windscribe.settings.byApp names options that do not exist: ${lib.concatStringsSep ", " unknown} — a misspelt entry filters nothing and the option keeps overwriting the App.";
      }
    )
    ++ lib.optional (s.protocolTweaks == "enabled") {
      assertion = s.amneziawgPreset != null;
      message = need "amneziawgPreset" ''protocolTweaks = "enabled"'';
    }
    ++ lib.optional (s.connection != null && s.connection.isAutomatic == false) {
      assertion = s.connection.protocol != null;
      message = need "connection.protocol" "connection.isAutomatic = false";
    }
    ++ lib.optional (s.packetSize != null && s.packetSize.isAutomatic == false) {
      assertion = s.packetSize.mtu != null;
      message = need "packetSize.mtu" "packetSize.isAutomatic = false";
    }
    ++ lib.optional (s.macSpoofing != null && s.macSpoofing.isEnabled == true) {
      assertion = s.macSpoofing.macAddress != null;
      message = need "macSpoofing.macAddress" "macSpoofing.isEnabled = true";
    }
    ++ lib.optional (s.connectedDns != null && s.connectedDns.type == "controld") {
      assertion = s.connectedDns.controldApiKey != null;
      message = need "connectedDns.controldApiKey" ''connectedDns.type = "controld"'';
    }
    ++ lib.optional (s.connectedDns != null && s.connectedDns.type == "custom") {
      assertion = s.connectedDns.upStream1 != null;
      message = need "connectedDns.upStream1" ''connectedDns.type = "custom"'';
    }
    ++ lib.optional (s.connectedDns != null && s.connectedDns.isSplitDns == true) {
      assertion = s.connectedDns.hostnames != null && s.connectedDns.hostnames != [ ];
      message = need "connectedDns.hostnames" "connectedDns.isSplitDns = true";
    }
    ++ lib.optional (s.decoyTraffic != null && s.decoyTraffic.isEnabled == true) {
      assertion = s.decoyTraffic.volume != null;
      message = need "decoyTraffic.volume" "decoyTraffic.isEnabled = true";
    }
    ++
      lib.optional
        (
          s.splitTunneling != null
          && s.splitTunneling.settings != null
          && s.splitTunneling.settings.active == true
        )
        {
          assertion = s.splitTunneling.settings.mode != null;
          message = need "splitTunneling.settings.mode" "splitTunneling.settings.active = true";
        }
    ++ lib.optionals (s.proxy != null && (s.proxy.option == "http" || s.proxy.option == "socks")) [
      {
        assertion = s.proxy.address != null;
        message = need "proxy.address" ''proxy.option = "http" or "socks"'';
      }
      {
        assertion = s.proxy.port != null;
        message = need "proxy.port" ''proxy.option = "http" or "socks"'';
      }
    ]
    ++ lib.optionals (s.shareProxyGateway != null && s.shareProxyGateway.isEnabled == true) [
      {
        assertion = s.shareProxyGateway.proxySharingMode != null;
        message = need "shareProxyGateway.proxySharingMode" "shareProxyGateway.isEnabled = true";
      }
      {
        assertion = s.shareProxyGateway.port != null;
        message = need "shareProxyGateway.port" "shareProxyGateway.isEnabled = true";
      }
    ]
    ++ completes "connection" "isAutomatic" [ "protocol" "port" ] s.connection
    ++ completes "packetSize" "isAutomatic" [ "mtu" ] s.packetSize
    ++ completes "firewall" "mode" [ "when" ] s.firewall
    ++ completes "decoyTraffic" "isEnabled" [ "volume" ] s.decoyTraffic
    ++ completes "proxy" "option" [
      "address"
      "port"
      "username"
      "password"
    ] s.proxy
    ++ completes "connectedDns" "type" [
      "upStream1"
      "upStream2"
      "isSplitDns"
      "hostnames"
      "controldApiKey"
    ] s.connectedDns
    ++ completes "splitTunneling.settings" "active" [ "mode" ] (
      if s.splitTunneling == null then null else s.splitTunneling.settings
    )
    ++
      lib.optional
        (
          s.shareProxyGateway != null
          && (s.shareProxyGateway.username != null || s.shareProxyGateway.password != null)
        )
        {
          assertion = s.shareProxyGateway.requireAuth != null;
          message = need "shareProxyGateway.requireAuth" "shareProxyGateway.username or shareProxyGateway.password is set";
        }
    ++ lib.optional (s.soundSettings != null && s.soundSettings.disconnectedSoundType == "custom") {
      assertion = s.soundSettings.disconnectedSoundPath != null;
      message = need "soundSettings.disconnectedSoundPath" ''soundSettings.disconnectedSoundType = "custom"'';
    }
    ++ lib.optional (s.soundSettings != null && s.soundSettings.connectedSoundType == "custom") {
      assertion = s.soundSettings.connectedSoundPath != null;
      message = need "soundSettings.connectedSoundPath" ''soundSettings.connectedSoundType = "custom"'';
    }
    ++
      lib.optional
        (s.backgroundSettings != null && s.backgroundSettings.disconnectedBackgroundType == "custom")
        {
          assertion = s.backgroundSettings.backgroundImageDisconnected != null;
          message = need "backgroundSettings.backgroundImageDisconnected" ''backgroundSettings.disconnectedBackgroundType = "custom"'';
        }
    ++
      lib.optional
        (s.backgroundSettings != null && s.backgroundSettings.connectedBackgroundType == "custom")
        {
          assertion = s.backgroundSettings.backgroundImageConnected != null;
          message = need "backgroundSettings.backgroundImageConnected" ''backgroundSettings.connectedBackgroundType = "custom"'';
        }
    ++ lib.optionals (s.favoriteLocations != null) (
      map (
        e:
        let
          missing =
            lib.optional (!(e ? type)) "type"
            ++ lib.optional (!(e ? id)) "id"
            ++ lib.optional (!(e ? city)) "city";
        in
        {
          assertion = missing == [ ];
          message = "programs.windscribe.settings.favoriteLocations entry is missing fields: ${lib.concatStringsSep ", " missing} — App drops entries without type, id, and city.";
        }
      ) s.favoriteLocations
    )
    ++ lib.optionals (s.networkPreferredProtocols != null) (
      lib.mapAttrsToList (k: v: {
        assertion = builtins.isAttrs v && (v ? protocol || v ? port || v ? isAutomatic);
        message = "programs.windscribe.settings.networkPreferredProtocols.\"${k}\" must define at least one of protocol, port, or isAutomatic — an empty entry overrides nothing.";
      }) s.networkPreferredProtocols
    )
    ++ lib.optional (s.persistentState != null) {
      assertion = (s.persistentState ? networks) && builtins.isList s.persistentState.networks;
      message = "programs.windscribe.settings.persistentState must define networks as a list — the App assigns the whitelist from this key unconditionally, so omitting it clears every network the App had stored.";
    }
    ++ lib.optionals (s.renamedLocations != null && s.renamedLocations ? locations) (
      lib.concatMap (
        loc:
        lib.optional (!(loc ? id) || !(loc ? country)) {
          assertion = false;
          message = "programs.windscribe.settings.renamedLocations location entry needs both id and country — the App assigns the country unconditionally, so a missing one arrives empty.";
        }
        ++ lib.optionals (loc ? cities) (
          map (c: {
            assertion = (c ? id) && (c ? name) && (c ? nickname);
            message = "programs.windscribe.settings.renamedLocations city entry needs id, name and nickname — the App assigns name and nickname unconditionally, so a missing key arrives as an empty string and erases the rename stored for that city.";
          }) loc.cities
        )
      ) s.renamedLocations.locations
    )
    ++
      lib.optionals
        (
          s.persistentState != null
          && s.persistentState ? networks
          && builtins.isList s.persistentState.networks
        )
        (
          map (
            e:
            let
              missing =
                lib.optional (!(e ? networkOrSsid)) "networkOrSsid" ++ lib.optional (!(e ? trustType)) "trustType";
            in
            {
              assertion = missing == [ ];
              message = ''programs.windscribe.settings.persistentState.networks entry is missing fields: ${lib.concatStringsSep ", " missing} — networkOrSsid keys the per-network state, trustType decides whether the App auto-secures it instead of defaulting to "Secured".'';
            }
          ) s.persistentState.networks
        );
}
