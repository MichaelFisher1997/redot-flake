# Redot Engine Nix Flake

A Nix flake for [Redot Engine](https://github.com/Redot-Engine/redot-engine), a community-driven fork of Godot.

This flake provides prebuilt Redot editor binaries as `packages.<system>.default`
(also available as `packages.<system>.redot`) plus an `apps.<system>.default` for
`nix run`. It does not provide a NixOS or Home Manager module — add the package
to your config as shown below.

## Usage

### Run without installing

```bash
nix run github:MichaelFisher1997/redot-flake
```

### Install imperatively

```bash
nix profile install github:MichaelFisher1997/redot-flake
```

### NixOS (flake)

In the `flake.nix` that defines your system:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    redot.url = "github:MichaelFisher1997/redot-flake";
  };

  outputs = { self, nixpkgs, redot, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit redot; };
      modules = [ ./configuration.nix ];
    };
  };
}
```

Then in `configuration.nix`:

```nix
{ pkgs, redot, ... }: {
  environment.systemPackages = [
    redot.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

### Home Manager (flake)

In the `flake.nix` that defines your home configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    redot.url = "github:MichaelFisher1997/redot-flake";
  };

  outputs = { self, nixpkgs, home-manager, redot, ... }: {
    homeConfigurations."user@host" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit redot; };
      modules = [ ./home.nix ];
    };
  };
}
```

Then in `home.nix`:

```nix
{ pkgs, redot, ... }: {
  home.packages = [
    redot.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

The flake does not define a `devShell`, so `nix develop` opens the package build
environment rather than a development shell.

## Supported Platforms

- ✅ x86_64-linux
- ✅ aarch64-linux  
- ✅ x86_64-darwin (macOS Intel)
- ✅ aarch64-darwin (macOS Apple Silicon)

## Auto-Updates

This flake automatically updates via GitHub Actions:

- **Redot releases** — checked weekly (Mondays at 6 AM UTC). When a new stable
  (non-prerelease) release is found, the version and platform hashes in
  `flake.nix` are updated, the package is built to verify it works, and the
  change is pushed directly to `main`.
- **flake.lock** — updated weekly (Mondays at 4 AM UTC), validated with a build,
  and pushed directly to `main`.

## Manual Update

To manually update to the latest release:

1. Check the [Redot releases](https://github.com/Redot-Engine/redot-engine/releases)
2. Update the `version` in `flake.nix`
3. Update the hashes for each platform using `nix-prefetch-url`
4. Run `nix flake update` to update dependencies

## Building Locally

```bash
# Build the package
nix build

# Run without installing
nix run

# Build and install to profile
nix profile install
```

## License

This flake packaging is provided under the same license as Redot Engine (MIT).
