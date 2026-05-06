{
  description = "Crdtlib";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      crane,
      rust-overlay,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { system, pkgs, ... }:
        let
          rustPkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };

          craneLib = (crane.mkLib rustPkgs).overrideToolchain (p: p.rust-bin.stable.latest.default);
        in
        {
          packages = {
            bindings-rust = craneLib.buildPackage {
              src = craneLib.cleanCargoSource ./.;
              cargoExtraArgs = "-p crdtlib";
              pname = "crdtlib";
            };
          };
          devShells = rec {
            bindings-rust = craneLib.devShell {
              checks = self.checks.${system};
            };

            default = pkgs.mkShell {
              inputsFrom = [ bindings-rust ];
              packages = with pkgs; [
                lean4
                pkg-config
                gmp
                libuv
                clang
              ];
            };
          };
        };
    };
}
