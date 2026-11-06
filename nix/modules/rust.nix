# The Rust workspace in `lang/rust`, built with crane on the stable toolchain from rust-overlay.
{ inputs, ... }:
{
  perSystem =
    { system, self', ... }:
    let
      rustPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ (import inputs.rust-overlay) ];
      };

      craneLib = (inputs.crane.mkLib rustPkgs).overrideToolchain (
        p:
        p.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
          ];
        }
      );

      src = craneLib.cleanCargoSource ../..;

      # The crates that build without Lean: `crdtlib-bindings` links the shared libraries that
      # `lake` builds, which the sandbox does not have.
      nativeArgs = {
        inherit src;
        pname = "crdtlib";
        cargoExtraArgs = "-p crdtlib-api -p crdtlib";
      };
      native = nativeArgs // {
        cargoArtifacts = craneLib.buildDepsOnly nativeArgs;
      };
    in
    {
      packages.bindings-rust = craneLib.buildPackage {
        inherit src;
        cargoExtraArgs = "-p crdtlib-bindings";
        pname = "crdtlib-bindings";
      };

      checks = {
        rust-fmt = craneLib.cargoFmt {
          inherit src;
          pname = "crdtlib-workspace";
        };
        rust-clippy = craneLib.cargoClippy (
          native // { cargoClippyExtraArgs = "--all-targets -- --deny warnings"; }
        );
        rust-test = craneLib.cargoTest native;
        rust-doc = craneLib.cargoDoc (native // { RUSTDOCFLAGS = "--deny warnings"; });
      };

      devShells.bindings-rust = craneLib.devShell {
        checks = self'.checks;
      };
    };
}
