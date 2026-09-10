# Redot Engine Nix Flake

A Nix flake for [Redot Engine](https://github.com/Redot-Engine/redot-engine), a community-driven fork of Godot.

## Usage

### Running Redot directly

```bash
nix run github:MichaelFisher1997/redot-flake
```

### Installing in your system

Add to your `flake.nix`:

```nix
{
  inputs = {
    redot.url = "github:MichaelFisher1997/redot-flake";
  };
  
  outputs = { self, nixpkgs, redot }: {
    # Add redot.packages.${system}.default to your packages
  };
}
```

### Development shell

```bash
nix develop
```

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