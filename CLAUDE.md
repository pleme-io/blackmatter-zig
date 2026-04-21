# blackmatter-zig — Claude Orientation

One-sentence purpose: prebuilt Zig 0.15 + from-source zls overlay and
direct-importable `lib/` helpers.

## Classification

- **Archetype:** `blackmatter-component-custom-overlay`
- **Flake shape:** **custom** (does NOT go through mkBlackmatterFlake)
- **Reason:** Same as blackmatter-go — exposes `lib/{overlay,bootstrap,zls,deps}.nix`
  for direct import by downstream flakes.

## Where to look

| Intent | File |
|--------|------|
| Overlay definition | `lib/overlay.nix` |
| Zig toolchain (prebuilt) | `lib/zig/bootstrap.nix` |
| zls (from source) | `lib/zig/zls.nix` |

## Upstream origin

Canonical source is **substrate** (`substrate/lib/zig-overlay.nix`). This
repo pins and re-exports.
