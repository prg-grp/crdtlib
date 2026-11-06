# The default shell: Lean, the Rust toolchain, and the native libraries the Lean bindings link.
# Also has `cargo verus` and `cargo prusti` for `lang/rust/{verus,prusti}`, where available, so
# that they work under direnv.
{
  perSystem =
    { system, pkgs, lib, self', ... }:
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = [ self'.devShells.bindings-rust ];
        packages =
          with pkgs;
          [
            elan
            pkg-config
            gmp
            libuv
            clang
          ]
          ++ lib.optionals (system == "aarch64-darwin") [
            self'.packages.verus
            self'.packages.prusti
            jdk21_headless
          ];
      };
    };
}
