<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://static.windscribe.com/v2/img/WS-Logo-white@2x.png">
    <source media="(prefers-color-scheme: light)" srcset="https://static.windscribe.com/v2/img/WS-Logo@2x.png">
    <img alt="Windscribe" width="220">
  </picture>
  <br><br>
  windscribe-nixos
</h1>

<p align="center"><em>Windscribe VPN client packaged for NixOS by <a href="https://github.com/Varmisanth">@Varmisanth</a></em></p>

<p align="center">
  <img alt="upstream" src="https://img.shields.io/github/v/release/Windscribe/Desktop-App?label=upstream&color=blueviolet">
  <a href="https://github.com/Varmisanth/windscribe-nixos/actions/workflows/check.yml">
    <img alt="check" src="https://github.com/Varmisanth/windscribe-nixos/actions/workflows/check.yml/badge.svg">
  </a>
  <a href="LICENSE">
    <img alt="license" src="https://img.shields.io/badge/license-GPL--2.0-blue.svg">
  </a>
  <img alt="updated" src="https://img.shields.io/github/last-commit/Varmisanth/windscribe-nixos?label=updated">
  <a href="https://varmisanth.cachix.org">
    <img alt="cachix" src="https://img.shields.io/badge/cachix-varmisanth-blue.svg">
  </a>
</p>

## Quickstart via Flakes on NixOS

```nix
{
  inputs.windscribe-nixos.url = "github:varmisanth/windscribe-nixos";
  outputs = { nixpkgs, windscribe-nixos, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        windscribe-nixos.nixosModules.windscribe
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ windscribe-nixos.overlays.windscribe ];
          environment.systemPackages = [ pkgs.windscribe ];
          services.windscribe = {
            enable = true;       # default: false
            autoStart = false;   # default: true
            users = [ "alice" ]; # added to windscribe group for IPC access
          };
        })
      ];
    };
  };
}
```

The NixOS module brings up the helper service, `windscribe` group, polkit policy and runtime user.

The overlay and `environment.systemPackages` add `Windscribe` with `windscribe-cli` to every user's `$PATH`.

With `autoStart = false` the unit is defined but not enabled at boot.

Start manually via `sudo systemctl start windscribe-helper`.

## Via Home Manager with Flakes

Alternative to `environment.systemPackages` — installs `Windscribe` with `windscribe-cli` per-user.

Works integrated with NixOS or as a standalone flake.

**As part of NixOS:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    windscribe-nixos.url = "github:varmisanth/windscribe-nixos";
  };
  outputs = { nixpkgs, home-manager, windscribe-nixos, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        windscribe-nixos.nixosModules.windscribe
        home-manager.nixosModules.home-manager
        ({ ... }: {
          services.windscribe = {
            enable = true;
            users = [ "alice" ];
          };
          home-manager.users.alice = {
            imports = [ windscribe-nixos.homeManagerModules.windscribe ];
            programs.windscribe.enable = true;
          };
        })
      ];
    };
  };
}
```

**Non part of NixOS:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    windscribe-nixos.url = "github:varmisanth/windscribe-nixos";
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
> Standalone HM only puts the binaries on `$PATH`.
>
> The helper daemon must still be running on the host — install `nixosModules.windscribe` separately.

## Via Legacy Channels

**NixOS only:**

```nix
let
  windscribe-nixos = builtins.fetchTarball
    "https://github.com/varmisanth/windscribe-nixos/archive/refs/heads/main.tar.gz";
in {
  imports = [ "${windscribe-nixos}/os.nix" ];
  nixpkgs.overlays = [
    (final: _prev: { windscribe = import "${windscribe-nixos}/package.nix" { pkgs = final; }; })
  ];
  environment.systemPackages = [ pkgs.windscribe ];
  services.windscribe = {
    enable = true;
    users = [ "alice" ];
  };
}
```

**With Home Manager as part of NixOS:**

```nix
let
  windscribe-nixos = builtins.fetchTarball
    "https://github.com/varmisanth/windscribe-nixos/archive/refs/heads/main.tar.gz";
in {
  imports = [
    "${windscribe-nixos}/os.nix"
    <home-manager/nixos>
  ];
  services.windscribe = {
    enable = true;
    users = [ "alice" ];
  };
  home-manager.users.alice = {
    imports = [ "${windscribe-nixos}/hm.nix" ];
    programs.windscribe.enable = true;
  };
}
```

**Home Manager as non part of NixOS:**

```nix
let
  windscribe-nixos = builtins.fetchTarball
    "https://github.com/varmisanth/windscribe-nixos/archive/refs/heads/main.tar.gz";
in {
  imports = [ "${windscribe-nixos}/hm.nix" ];
  programs.windscribe.enable = true;
}
```

## Options

| Option | Type | Default |
|---|---|---|
| `services.windscribe.enable` | bool | `false` |
| `programs.windscribe.enable` | bool | `false` |
| `services.windscribe.users` | list of str | `[ ]` |
| `services.windscribe.autoStart` | bool | `true` |

## Binary cache

To skip building from source, the flake fetches pre-built artifacts from [`varmisanth.cachix.org`](https://app.cachix.org/cache/varmisanth).

Nix prompts to accept the substituter on the first build.

For legacy channels or non-interactive setups add it manually:

```nix
nix.settings = {
  substituters = [ "https://varmisanth.cachix.org" ];
  trusted-public-keys = [ "varmisanth.cachix.org-1:rt04yjDDJKDWe+h6B1XQWfdsSDUX6uks+9IKVBjn2d8=" ];
};
```

## License

[GPL-2.0-only](LICENSE), inherited from [Windscribe Desktop-App](https://github.com/Windscribe/Desktop-App).
