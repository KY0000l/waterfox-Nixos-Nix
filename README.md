# Waterfox for Nix

> **Note:** This project is not fully tested and may have Nix-specific quirks. Not all functionality is guaranteed.

A small Nix flake that packages the official prebuilt [Waterfox](https://www.waterfox.net/) binary release for NixOS. It does not contain the browser source code. It downloads the release tarball from Waterfox's CDN when you build.

- **Platform:** `x86_64-linux`
- **Current version:** 6.7.7

## How it works

| File | Purpose |
|------|---------|
| `flake.nix` | Exposes the package (`packages.x86_64-linux.waterfox`), an overlay (`overlays.default`), and a NixOS module (`nixosModules.default`) |
| `package.nix` | The derivation: fetches the tarball, patches its binaries for NixOS, wraps them, and adds a desktop entry |
| `flake.lock` | Pins the exact `nixpkgs` revision used |

### What the package does

Prebuilt Linux binaries can't run on NixOS as-is, so `package.nix` handles several things for you:

- **Binary patching:** `autoPatchelfHook` points the binaries at Nix store libraries. It uses `patchelfUnstable` with `--no-clobber-old-sections`, because Mozilla's `relrhack` libraries crash at startup (segfault in `_dl_init`) if stock `patchelf` moves ELF sections around. Stripping is disabled for the same reason.
- **Runtime libraries:** The wrapper adds PulseAudio, PipeWire, ALSA, VA-API, GL, pciutils and ffmpeg to `LD_LIBRARY_PATH`. Waterfox loads these with `dlopen`, so without this it falls back to the ALSA audio backend (no sound on PipeWire systems).
- **Stable profile:** The wrapper sets `MOZ_LEGACY_PROFILES=1`, so Waterfox keeps using your default profile instead of creating a new one every time the store path changes on a rebuild.
- **Desktop entry and icon:** Installed so Waterfox shows up in your application launcher and can be set as the default browser.

## Installation

### 1. Add the flake input

In your system's `flake.nix`:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  waterfox = {
    url = "github:KY0000l/waterfox-Nixos-Nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

The `follows` line makes Waterfox use your `nixpkgs` instead of pulling in a second copy.

### 2. Use the NixOS module (recommended)

Add the module to your system and enable it. Make sure your inputs are in scope (`inputs@{ ... }`):

```nix
modules = [
  inputs.waterfox.nixosModules.default
  {
    programs.waterfox = {
      enable = true;
      plasmaIntegration = true; # optional, see below
    };
  }
  ./configuration.nix
];
```

This installs Waterfox and also adds the overlay, so `pkgs.waterfox` is available everywhere (including Home Manager with `useGlobalPkgs = true`). You don't need to add `waterfox` to `systemPackages` yourself.

#### Module options

| Option | Default | Description |
|--------|---------|-------------|
| `programs.waterfox.enable` | `false` | Install Waterfox and enable the overlay |
| `programs.waterfox.package` | this flake's `waterfox` | The package to install, in case you want to override it |
| `programs.waterfox.plasmaIntegration` | `false` | Install KDE's `plasma-browser-integration` and link its native messaging host for each user |

#### KDE Plasma integration

With `plasmaIntegration = true` the module:

1. Installs `kdePackages.plasma-browser-integration` (the native messaging host).
2. Creates `~/.mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json` as a symlink, using `systemd.user.tmpfiles`. Waterfox on NixOS doesn't find the host through the system profile on its own, so the per-user symlink is what makes it connect.

The symlink appears at your next login after the first rebuild. To create it immediately:

```sh
systemctl --user start systemd-tmpfiles-setup.service
```

You still need to install the **Plasma Integration** extension from addons.mozilla.org and enable it in `about:addons`.

### 2. Option B: overlay only

If you'd rather not use the module, add the overlay:

```nix
nixpkgs.overlays = [
  inputs.waterfox.overlays.default
];
```

Then add the package, in `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  waterfox
];
```

Or with Home Manager:

```nix
home.packages = [ pkgs.waterfox ];
```

With this option you handle the Plasma integration yourself (see [Troubleshooting](#troubleshooting)).

### 3. Rebuild

```sh
sudo nixos-rebuild switch --flake .#yourhostname
```

## Try it without installing

```sh
nix run github:KY0000l/waterfox-Nixos-Nix
```

## Updating

Pull in a new version of this flake (and any packaging fixes):

```sh
nix flake update waterfox
```

## Notes

- Waterfox is distributed under its own license. This repo only packages the official binaries and is not affiliated with Waterfox.
- Only `x86_64-linux` is supported, matching the upstream tarball.
- The NixOS module and Plasma integration are nearly untested.
