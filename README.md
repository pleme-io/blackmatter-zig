# blackmatter-zig

Prebuilt Zig compiler and from-source zls overlay, re-exported from substrate.

## Overview

Provides a Nix overlay with a prebuilt Zig compiler (from ziglang.org, 4 platforms) and zls built from source using that Zig. Overrides `pkgs.zig` and exposes `pkgs.zigToolchain` and `pkgs.zls`. The canonical implementation lives in substrate; this repo re-exports it as a standalone flake input.

## Flake Outputs

- `overlays.default` -- Zig + zls overlay (`pkgs.zig`, `pkgs.zigToolchain`, `pkgs.zls`)
- `packages.<system>.zig` -- Zig toolchain
- `packages.<system>.zls` -- Zig Language Server
- `lib` -- standalone import paths for overlay, bootstrap, zls, deps

## Usage

```nix
{
  inputs.blackmatter-zig = {
    url = "github:pleme-io/blackmatter-zig";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.substrate.follows = "substrate";
  };
}
```

Apply the overlay:

```nix
overlays = [ blackmatter-zig.overlays.default ];
```

## Structure

- `lib/overlay.nix` -- overlay factory (synced from substrate)
- `lib/zig/bootstrap.nix` -- prebuilt Zig binary derivation
- `lib/zig/zls.nix` -- zls from-source build
- `lib/zig/deps.nix` -- zon2nix dependency resolution
