# Nightly release binary of Prusti, for `cargo prusti` in `lang/rust/prusti`. It runs rustc from the
# rustup toolchain it pins (`rustup toolchain install nightly-2026-08-15`), and its Viper backend
# runs on the JDK in the default shell.
{
  perSystem =
    { system, pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs (system == "aarch64-darwin") {
        prusti = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "prusti";
          version = "2026-10-27-1410";
          src = pkgs.fetchzip {
            url = "https://github.com/viperproject/prusti-dev/releases/download/v-${version}/prusti-release-macos-arm64.zip";
            hash = "sha256-RA/lILtrjtj+2UOjDnM2mr6fU7LS8ivjQX9w0Opue+k=";
            stripRoot = false;
          };
          nativeBuildInputs = [ pkgs.makeWrapper ];
          # Keep the signed binaries as released.
          dontFixup = true;
          installPhase = ''
            mkdir -p $out/libexec $out/bin
            cp -r . $out/libexec/prusti
            for b in cargo-prusti prusti-rustc; do
              makeWrapper $out/libexec/prusti/$b $out/bin/$b
            done
          '';
          meta.platforms = [ "aarch64-darwin" ];
        };
      };
    };
}
