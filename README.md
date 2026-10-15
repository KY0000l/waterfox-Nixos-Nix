# Waterfox for Nix

Note: This project is not fully tested and my have nix specific quirks. Not all functionality is guaranteed.

A small Nix flake that packages the official prebuilt [Waterfox](https://www.waterfox.net/) binary release for NixOS. It does not contain the browser source code. It downloads the release tarball from Waterfox's CDN when you build.

- **Platform:** `x86_64-linux`
- **Current version:** 6.7.6

## How it works

| File | Purpose |
|------|---------|
| `flake.nix` | Exposes the package (`packages.x86_64-linux.waterfox`) and an overlay (`overlays.default`) |
| `package.nix` | The derivation: fetches the tarball, patches its binaries for NixOS, and adds a desktop entry |
| `flake.lock` | Pins the exact `nixpkgs` revision used |

The overlay is what lets you write plain `waterfox` in your package lists. It adds a `waterfox` attribute to `pkgs`, just like any package from nixpkgs.

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

### 2. Enable the overlay

Inside `outputs`, make sure your inputs are in scope (`inputs@{ ... }`) and add the overlay to your system modules:

```nix
nixpkgs.overlays = [
  inputs.waterfox.overlays.default
];
```

### 3. Add the package

In `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  waterfox
];
```

Or, with Home Manager:

```nix
home.packages = [ pkgs.waterfox ];
```

Then rebuild:

```sh
sudo nixos-rebuild switch --flake .#yourhostname
```

## Try it without installing

```sh
nix run github:KY0000l/waterfox
```

## Updating

Pull in a new version of this flake (and any packaging fixes):

```sh
nix flake update waterfox
```

When Waterfox releases a new version, a maintainer needs to bump `version` and `hash` in `package.nix`. Get the new hash with:

```sh
nix-prefetch-url --type sha256 \
  https://cdn.waterfox.com/waterfox/releases/<version>/Linux_x86_64/waterfox-<version>.tar.bz2 \
  | xargs nix hash to-sri --type sha256
```

## Notes

- Waterfox is distributed under its own license. This repo only packages the official binaries and is not affiliated with Waterfox.
- Only `x86_64-linux` is supported, matching the upstream tarball.
