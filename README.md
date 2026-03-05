# blackmatter-zig

Zig toolchain overlay for the pleme-io Nix ecosystem. Provides a prebuilt Zig 0.15.2 compiler from ziglang.org and a from-source build of zls 0.15.1 (the Zig Language Server). The overlay replaces `pkgs.zig` and `pkgs.zls` with these pinned versions, ensuring consistent Zig tooling across all projects in the stack. Dependencies are managed via the zon2nix linkFarm pattern for fully hermetic, sandbox-compatible builds.

## Architecture

```
blackmatter-zig
├── flake.nix            ← overlay + packages + lib exports
└── lib/
    ├── overlay.nix      ← mkZigOverlay: creates the Nix overlay
    └── zig/
        ├── bootstrap.nix  ← prebuilt Zig 0.15.2 from ziglang.org
        ├── zls.nix        ← zls 0.15.1 built from source with Zig
        └── deps.nix       ← zls build dependencies (zon2nix linkFarm)
```

**Build chain:**

1. **Bootstrap** -- Prebuilt Zig 0.15.2 binary downloaded from ziglang.org (4 platform variants)
2. **zls** -- Zig Language Server 0.15.1 compiled from source using the prebuilt Zig compiler, with dependencies pre-fetched via the zon2nix pattern
3. **Overlay** -- Replaces `pkgs.zig` and `pkgs.zls` to use these pinned versions

All source files are synced copies from the canonical source at [substrate](https://github.com/pleme-io/substrate). Comments in each file note `CANONICAL SOURCE: substrate`.

## Features

- **Prebuilt Zig 0.15.2** -- official binary from ziglang.org, no compilation required
- **From-source zls 0.15.1** -- built with the provided Zig compiler for version alignment
- **zon2nix dependency management** -- zls dependencies (diffz, known-folders, lsp-kit) fetched as a linkFarm for fully hermetic builds
- **4-platform support** -- x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- **Simple overlay** -- single `mkZigOverlay {}` call replaces `pkgs.zig` and `pkgs.zls`
- **Standalone lib exports** -- importable paths for use outside the flake system

## Installation

### As a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    blackmatter-zig = {
      url = "github:pleme-io/blackmatter-zig";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, blackmatter-zig, ... }: {
    # Apply the overlay to get pkgs.zig, pkgs.zigToolchain, pkgs.zls
    devShells.x86_64-linux.default = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ blackmatter-zig.overlays.default ];
      };
    in pkgs.mkShell {
      packages = [ pkgs.zig pkgs.zls ];
    };
  };
}
```

### Standalone packages

```bash
# Run zls (default package)
nix run github:pleme-io/blackmatter-zig

# Build just the Zig compiler
nix build github:pleme-io/blackmatter-zig#zig

# Build zls
nix build github:pleme-io/blackmatter-zig#zls
```

## Usage

### Overlay

The overlay replaces these nixpkgs attributes:

| Attribute | Description |
|-----------|-------------|
| `pkgs.zigToolchain` | Prebuilt Zig 0.15.2 compiler from ziglang.org |
| `pkgs.zig` | Overridden to `zigToolchain` |
| `pkgs.zls` | Zig Language Server 0.15.1, built from source |

### Direct import (without flake)

```nix
# Import the overlay factory
zigOverlay = import "${blackmatter-zig}/lib/overlay.nix";
pkgs = import nixpkgs {
  inherit system;
  overlays = [ (zigOverlay.mkZigOverlay {}) ];
};

# Or import individual components
zigBootstrap = import "${blackmatter-zig}/lib/zig/bootstrap.nix";
zlsFromSource = import "${blackmatter-zig}/lib/zig/zls.nix";
```

### Lib exports

The flake exposes these importable paths via `lib`:

| Path | Description |
|------|-------------|
| `lib.overlay` | `./lib/overlay.nix` -- the `mkZigOverlay` factory |
| `lib.bootstrap` | `./lib/zig/bootstrap.nix` -- prebuilt Zig derivation |
| `lib.zls` | `./lib/zig/zls.nix` -- from-source zls derivation |
| `lib.deps` | `./lib/zig/deps.nix` -- zls dependency linkFarm |

## How zls Dependencies Work

zls uses Zig's build system (`build.zig.zon`) for dependency management. Since Nix builds run in a sandbox without network access, dependencies are pre-fetched using the zon2nix pattern:

1. `deps.nix` declares a `linkFarm` containing each dependency as a `fetchzip` derivation
2. Each entry's `name` matches the Zig package manager's expected directory name (hash-based)
3. The linkFarm is passed to `zig build install --system ${deps}`, which tells Zig to resolve packages from the local linkFarm instead of fetching from the network

Current zls 0.15.1 dependencies:

| Package | Source |
|---------|--------|
| diffz | [ziglibs/diffz](https://github.com/ziglibs/diffz) |
| known-folders | [ziglibs/known-folders](https://github.com/ziglibs/known-folders) |
| lsp-kit | [zigtools/lsp-kit](https://github.com/zigtools/lsp-kit) |

## Configuration

### Flake input follows

When used alongside other pleme-io flake inputs, follow shared dependencies to avoid duplicate copies in the closure:

```nix
blackmatter-zig = {
  url = "github:pleme-io/blackmatter-zig";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.fenix.follows = "fenix";       # if you have fenix as an input
  inputs.substrate.follows = "substrate"; # if you have substrate as an input
};
```

## Supported Platforms

| Platform | Zig 0.15.2 | zls 0.15.1 |
|----------|-----------|------------|
| `x86_64-linux` | yes | yes |
| `aarch64-linux` | yes | yes |
| `x86_64-darwin` | yes | yes |
| `aarch64-darwin` | yes | yes |

## Project Structure

```
blackmatter-zig/
├── flake.nix               # Flake: overlay, packages, lib exports
├── flake.lock              # Pinned dependencies (nixpkgs, fenix, substrate)
└── lib/
    ├── overlay.nix          # mkZigOverlay — creates the nixpkgs overlay
    └── zig/
        ├── bootstrap.nix    # Prebuilt Zig 0.15.2 binary
        ├── zls.nix          # zls 0.15.1 from-source build
        └── deps.nix         # zls dependencies (zon2nix linkFarm)
```

## Development

### Updating the Zig version

1. Update `version` and platform hashes in `lib/zig/bootstrap.nix`
2. Platform hashes are SHA-256 of the tarballs from https://ziglang.org/download/

### Updating zls

1. Update `version` and `src` hash in `lib/zig/zls.nix`
2. Regenerate `lib/zig/deps.nix` from the new `build.zig.zon` using the zon2nix pattern
3. Ensure the zls version is compatible with the Zig compiler version

### Syncing from substrate

All `lib/` files are synced copies from [substrate](https://github.com/pleme-io/substrate). When the canonical source is updated:

1. Copy files from `substrate/lib/zig-overlay.nix` to `lib/overlay.nix`
2. Copy files from `substrate/lib/zig/` to `lib/zig/`
3. Verify the `CANONICAL SOURCE: substrate` comments are preserved

## Related Projects

- [substrate](https://github.com/pleme-io/substrate) -- canonical source for the Zig overlay, bootstrap, and zls builder
- [blackmatter-ghostty](https://github.com/pleme-io/blackmatter-ghostty) -- primary consumer; builds Ghostty terminal from source using this Zig toolchain
- [blackmatter](https://github.com/pleme-io/blackmatter) -- home-manager module aggregator that pulls in this overlay
- [blackmatter-go](https://github.com/pleme-io/blackmatter-go) -- sister project for the Go toolchain overlay

## License

MIT (matching the Zig project license).
