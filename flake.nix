{
  description = "Blackmatter Zig — prebuilt Zig compiler, from-source zls, overlay, and tool builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, substrate }:
  let
    allSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

    forEachSystem = f: nixpkgs.lib.genAttrs allSystems (system: f {
      inherit system;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    });
  in {
    # ── Overlay ─────────────────────────────────────────────────────
    overlays.default = (import "${substrate}/lib/zig-overlay.nix").mkZigOverlay {};

    # ── Packages ────────────────────────────────────────────────────
    packages = forEachSystem ({ pkgs, ... }: {
      default = pkgs.zls;
      zig = pkgs.zigToolchain;
      zls = pkgs.zls;
    });

    # ── Lib exports (standalone import paths) ───────────────────────
    lib = {
      overlay = ./lib/overlay.nix;
      bootstrap = ./lib/zig/bootstrap.nix;
      zls = ./lib/zig/zls.nix;
      deps = ./lib/zig/deps.nix;
    };
  };
}
