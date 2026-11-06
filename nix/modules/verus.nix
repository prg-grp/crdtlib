# Release binary of Verus, for `cargo verus verify` in `lang/rust/verus`. It runs rustc from the
# rustup toolchain it pins (`rustup toolchain install 1.99.1`).
{
  perSystem =
    { system, pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs (system == "aarch64-darwin") {
        verus = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "verus";
          version = "0.2026.10.26.d17fbd0";
          src = pkgs.fetchzip {
            url = "https://github.com/verus-lang/verus/releases/download/release%2F${version}/verus-${version}-arm64-macos.zip";
            hash = "sha256-dAVigX3kwgqd8XByykwAxpusfXbCy5qS+5dVbeHzXug=";
          };
          nativeBuildInputs = [ pkgs.makeWrapper ];
          # Keep the signed binaries as released.
          dontFixup = true;
          installPhase = ''
            mkdir -p $out/libexec $out/bin
            cp -r . $out/libexec/verus
            for b in verus cargo-verus; do
              makeWrapper $out/libexec/verus/$b $out/bin/$b
            done
          '';
          meta.platforms = [ "aarch64-darwin" ];
        };
      };
    };
}
