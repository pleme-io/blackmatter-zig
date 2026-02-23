# Zig Overlay Module
#
# CANONICAL SOURCE: substrate (github:pleme-io/substrate)
# Keep in sync — direct file imports from consumers still use these paths.
#
# Provides a reusable Zig overlay with prebuilt compiler and from-source zls.
#
# Usage:
#   zigOverlay = import "${blackmatter-zig}/lib/overlay.nix";
#   pkgs = import nixpkgs {
#     inherit system;
#     overlays = [ (zigOverlay.mkZigOverlay {}) ];
#   };
#
# The overlay provides:
#   - pkgs.zigToolchain — prebuilt Zig compiler from ziglang.org
#   - pkgs.zig — overridden to use our toolchain
#   - pkgs.zls — built from source with our Zig
{
  # Create a Zig overlay with prebuilt compiler and from-source zls.
  #
  # Returns: An overlay function (final: prev: ...)
  mkZigOverlay = {}: final: prev: let
    zigToolchain = prev.callPackage ./zig/bootstrap.nix {};
    zlsFromSource = prev.callPackage ./zig/zls.nix {};
  in {
    inherit zigToolchain;
    zig = zigToolchain;
    zls = zlsFromSource;
  };
}
