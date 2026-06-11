<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://static.windscribe.com/v2/img/WS-Logo-white@2x.png">
    <source media="(prefers-color-scheme: light)" srcset="https://static.windscribe.com/v2/img/WS-Logo@2x.png">
    <img alt="Windscribe" width="220">
  </picture>
  <br><br>
  windscribe-nixos
</h1>

<p align="center"><em>Windscribe VPN client packaged for NixOS</em></p>

<p align="center">
  <img alt="packaged" src="https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2FVarmisanth%2Fwindscribe-nixos%2Fmain%2Fpkgs%2Fapp%2Fdesktop-app.nix&search=version%20%3D%20%22%28%5B0-9.%5D%2B%29%22&replace=%241&label=packaged&color=blueviolet">
  <img alt="upstream" src="https://img.shields.io/github/v/release/Windscribe/Desktop-App?label=upstream&color=informational">
  <img alt="check" src="https://img.shields.io/github/actions/workflow/status/Varmisanth/windscribe-nixos/check.yml?branch=main&label=check">
  <img alt="license" src="https://img.shields.io/badge/license-GPL--2.0-blue.svg">
  <img alt="updated" src="https://img.shields.io/github/last-commit/Varmisanth/windscribe-nixos?label=updated">
  <a href="https://varmisanth.cachix.org">
    <img alt="cachix" src="https://img.shields.io/badge/cachix-varmisanth-blue.svg">
  </a>
</p>

## Quickstart via Flakes on NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    windscribe-nixos = {
      url = "github:Varmisanth/windscribe-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, windscribe-nixos, ... }: {
    nixosConfigurations.alice = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        windscribe-nixos.nixosModules.windscribe
        {
          programs.windscribe = {
            enable = true;
            users = [ "alice" ];
          };
        }
      ];
    };
  };
}
```

The NixOS module brings up the helper service.

It also creates the `windscribe` group and runtime user.

The package is installed system-wide automatically.

`Windscribe` lands in everyone's `$PATH`.

To skip the system-wide install, set `programs.windscribe.installPackage = false`.

Without the [binary cache](#binary-cache) in your own configuration, this builds from source.

## Via Home Manager with Flakes

Alternative to system-wide install — installs `Windscribe` per-user.

Works integrated with NixOS or as a standalone flake.

**As part of NixOS:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    windscribe-nixos = {
      url = "github:Varmisanth/windscribe-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { home-manager, nixpkgs, windscribe-nixos, ... }: {
    nixosConfigurations.alice = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        windscribe-nixos.nixosModules.windscribe
        home-manager.nixosModules.home-manager
        {
          programs.windscribe = {
            enable = true;
            users = [ "alice" ];
          };
          home-manager.users.alice = {
            imports = [ windscribe-nixos.homeManagerModules.windscribe ];
            programs.windscribe.enable = true;
          };
        }
      ];
    };
  };
}
```

**With standalone Home Manager on NixOS:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    windscribe-nixos = {
      url = "github:Varmisanth/windscribe-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { home-manager, nixpkgs, windscribe-nixos, ... }: {
    homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        windscribe-nixos.homeManagerModules.windscribe
        { programs.windscribe.enable = true; }
      ];
    };
  };
}
```

> [!NOTE]
>
> The HM module only installs the user-side binary.
>
> Pair it with `nixosModules.windscribe` in your NixOS configuration for the helper service.

## Via Legacy Channels

**NixOS only:**

```nix
let
  windscribe-nixos = builtins.fetchTarball
    "https://github.com/Varmisanth/windscribe-nixos/archive/refs/heads/main.tar.gz";
in {
  imports = [ "${windscribe-nixos}/os.nix" ];
  programs.windscribe = {
    enable = true;
    users = [ "alice" ];
  };
}
```

**With Home Manager as part of NixOS:**

```nix
let
  windscribe-nixos = builtins.fetchTarball
    "https://github.com/Varmisanth/windscribe-nixos/archive/refs/heads/main.tar.gz";
in {
  imports = [
    "${windscribe-nixos}/os.nix"
    <home-manager/nixos>
  ];
  programs.windscribe = {
    enable = true;
    users = [ "alice" ];
  };
  home-manager.users.alice = {
    imports = [ "${windscribe-nixos}/hm.nix" ];
    programs.windscribe.enable = true;
  };
}
```


## Options

### NixOS module — `programs.windscribe`

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Enable the helper service |
| `app.startupBy` | enum | `"nix"` | Which mechanism starts the App:<br>`"nix"` — systemd user unit<br>`"app"` — App's own autostart entry |
| `app.autoStart` | bool | `false` | Whether the App starts with the session |
| `installPackage` | bool | auto | Install `Windscribe` system-wide<br>Off when Home Manager and `users` are set |
| `users` | list of str | `[ ]` | Users granted `windscribe` group IPC<br>HM module auto-injected when present |
| `purgeUserData` | bool | `false` | Erase `~/.config/Windscribe` when disabled<br>The App's own account and session |
| `settings` | submodule | `{ }` | Preferences overlay — see [Settings](#settings) |
| `preferencesFile` | nullOr path | `null` | Windscribe Export JSON used as base state<br>`settings` overlay merges on top |

### Home Manager module — `programs.windscribe`

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Install `Windscribe` per-user |
| `settings` | submodule | `{ }` | Preferences overlay — see [Settings](#settings) |
| `preferencesFile` | nullOr path | `null` | Per-user Windscribe Export JSON<br>Overrides the NixOS-level `preferencesFile` |

### Outputs

| Output | Description |
|---|---|
| `nixosModules.windscribe` | NixOS module |
| `homeManagerModules.windscribe` | Home Manager module |
| `overlays.windscribe` | Overlay exposing `pkgs.windscribe` |
| `packages.<system>.windscribe` | Windscribe package |

## Settings

`programs.windscribe.settings` declares Windscribe preferences in Nix.

Both modules expose the same option — pick the level that fits.

The NixOS module writes them to `/etc/windscribe/settings.json` system-wide.

The Home Manager module writes them to `~/.config/windscribe/settings.json` per-user.

The patched App reads the user file if there is one and the system file otherwise — whichever it picks, it uses alone.

So declare settings on one level.

A user file does not extend the system one, it replaces it.

The module asserts if both carry settings.

Unset values keep whatever Windscribe stored last.

Nix wins at every App launch.

Toggling a Nix-managed key in the App sticks until the App restarts.

Then the overlay rewrites it.

List the key under `byApp` if you want the App to fully own it.

| Domain | Keys |
|---|---|
| DNS | `dnsManager`, `dnsPolicy`, `connectedDns` |
| Connection | `connection`, `packetSize`, `serverRouting`, `ipStackEgress`, `customOvpnConfigsPath`, `advancedParameters` |
| Anti‑censorship | `protocolTweaks`, `amneziawgPreset`, `apiAntiCensorship`, `decoyTraffic`, `ignoreSslErrors`, `robert` |
| Network | `allowLanTraffic`, `keepAlive`, `macSpoofing`, `firewall`, `splitTunneling`, `networkPreferredProtocols` |
| Proxy | `proxy`, `shareProxyGateway` |
| App UI | `appSkin`, `language`, `locationOrder`, `trayIconColor`, `showLocationHealth`, `showNotifications`, `backgroundSettings`, `soundSettings`, `renamedLocations`, `favoriteLocations` |
| Session | `autoConnect`, `autoSecureNetworks`, `startMinimized`, `minimizeAndCloseToTray`, `persistentState` |

Every key declared end-to-end:

```nix
programs.windscribe.settings = {
  dnsManager = "systemd-resolved";
  dnsPolicy = "cloudflare";
  serverRouting = "regular";
  protocolTweaks = "enabled";
  ipStackEgress = "ipv4-only";
  allowLanTraffic = true;
  keepAlive = true;
  apiAntiCensorship = true;
  ignoreSslErrors = true;
  robert = {
    malware = true;
    ads = true;
    cryptominers = true;
    fakenews = true;
    porn = true;
    gambling = true;
    social = false;
    competitors = false;
  };
  language = "en";
  amneziawgPreset = "E - Baseline No Junk";
  customOvpnConfigsPath = "/etc/windscribe-ovpn";
  advancedParameters = ''
    tunnel-test-timeout 30
  '';
  renamedLocations = {
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
  favoriteLocations = [
    {
      type = 0;
      id = 110;
      city = "Bunker 42";
    }
  ];
  firewall = {
    mode = "always-on";
    when = "before-connection";
  };
  connection = {
    isAutomatic = false;
    protocol = "wireguard";
    port = 443;
  };
  packetSize = {
    isAutomatic = false;
    mtu = 1470;
  };
  connectedDns = {
    type = "custom";
    upStream1 = "1.1.1.1";
    upStream2 = "1.0.0.1";
    isSplitDns = true;
    hostnames = [
      "example.com"
      "internal.lan"
    ];
    controldApiKey = "ctrld-xxxxxxxxxxxxxxxx";
  };
  macSpoofing = {
    isEnabled = true;
    macAddress = "DE:AD:BE:EF:00:00";
    isAutoRotate = true;
  };
  proxy = {
    option = "http";
    address = "127.0.0.1";
    port = 8080;
    username = "alice";
    password = "secret";
  };
  decoyTraffic = {
    isEnabled = true;
    volume = "low";
  };
  shareProxyGateway = {
    isEnabled = true;
    proxySharingMode = "http";
    port = 8080;
    whileConnected = true;
    requireAuth = true;
    username = "alice";
    password = "secret";
  };
  soundSettings = {
    disconnectedSoundType = "custom";
    disconnectedSoundPath = "/etc/windscribe/disconnect.wav";
    connectedSoundType = "custom";
    connectedSoundPath = "/etc/windscribe/connect.wav";
  };
  backgroundSettings = {
    disconnectedBackgroundType = "custom";
    connectedBackgroundType = "custom";
    aspectRatioMode = "fill";
    backgroundImageDisconnected = "/etc/windscribe/bg-disconnected.jpg";
    backgroundImageConnected = "/etc/windscribe/bg-connected.jpg";
  };
  splitTunneling = {
    settings = {
      active = true;
      mode = "exclude";
    };
    apps = [
      {
        active = true;
        fullName = lib.getExe pkgs.firefox;
        name = "Firefox";
        icon = "${pkgs.firefox}/share/icons/hicolor/128x128/apps/firefox.png";
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
  };
  appSkin = "van-gogh";
  autoConnect = true;
  autoSecureNetworks = true;
  minimizeAndCloseToTray = true;
  showLocationHealth = true;
  showNotifications = true;
  startMinimized = true;
  locationOrder = "latency";
  trayIconColor = "os-theme";
};
```

> [!NOTE]
>
> Auto-start lives on the NixOS module, not here.
>
> `app.autoStart` decides whether the App starts with your session, and it is off by default.
>
> `app.startupBy` decides which mechanism does it.
>
> Under the default `"nix"` the systemd user unit is bound to the graphical session.
>
> The App is then told to leave `~/.config/autostart` alone.
>
> Under `"app"` the unit stays idle and Windscribe writes that entry itself.
>
> That needs `xdg.autostart.enable`, or a desktop that reads such entries on its own.
>
> Switching back to `"nix"` removes the entry the App left behind.

`byApp` skips listed options in the overlay — App owns them. Use the same names as the option set.

Nested structs merge in place.

Fields not declared in Nix keep whatever Windscribe stored last, so App-controlled state survives the overlay.

Practical defaults — things you actually tweak per network or per trip:

```nix
programs.windscribe.settings.byApp = [
  "connection"
  "packetSize"
  "connectedDns"
  "macSpoofing"
  "proxy"
  "decoyTraffic"
  "splitTunneling"
];
```

See [`settings.nix`](settings.nix) for the full option set and valid values.

## Disabling

Setting `enable = false` removes everything the module declared.

Files under `/etc/windscribe` and the helper service disappear on the next rebuild.

The `windscribe` user and group go with them, and Home Manager removes `~/.config/windscribe`.

One thing does not clean itself up.

Under `app.startupBy = "app"` the App writes `~/.config/autostart/windscribe.desktop` at runtime.

That symlink points into `/etc/windscribe` and would dangle, so disabling the module deletes it.

Windscribe keeps its own account and session under `~/.config/Windscribe`, which no rebuild touches.

Set `purgeUserData = true` to erase that as well.

Dropping the input from your flake leaves no code to run at all.

Keep the module imported with `enable = false` for one rebuild, then remove it.

## Update Channels

Windscribe defines three channels; a Nix build pins one.

- **Guinea Pig** — Sneak preview of new features and bug fixes. Can be unstable.
- **Beta** — Pre-release builds of new versions of Windscribe. Released more often.
- **Release** — Latest stable versions of Windscribe. Released least often.

Only the release channel ships today on the `main` branch.

A `guinea-pig` branch and a `.deb` wrapper for beta are planned.

Switch channels by pointing the flake input to the matching branch and rebuilding.

## Binary Cache

Pre-built artifacts live in [`varmisanth.cachix.org`](https://app.cachix.org/cache/varmisanth), pushed by CI on every commit to `main`.

Add the substituter to your own configuration to use them:

```nix
nix.settings = {
  substituters = [ "https://varmisanth.cachix.org" ];
  trusted-public-keys = [ "varmisanth.cachix.org-1:rt04yjDDJKDWe+h6B1XQWfdsSDUX6uks+9IKVBjn2d8=" ];
};
```

The `nixConfig` block in this flake does not reach you when the module is consumed as an input.

Nix reads `nixConfig` only from the flake it evaluates directly.

A system flake that lists this repository under `inputs` never sees it and builds from source.

The manual entry above is the only reliable way to get the cache.

It also requires your user to be listed in `trusted-users`.

## License

[GPL-2.0-only](LICENSE) — inherited from [Windscribe Desktop-App](https://github.com/Windscribe/Desktop-App).

## Acknowledgments

Packaged with help from [Claude Code](https://claude.com/claude-code).
