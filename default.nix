# The default hash is with nixpkgs unstable. Supply `pnpmDepsHash` if you want to pin nixpkgs.
{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  ic-nix = fetchFromGitHub {
    owner = "ninegua";
    repo = "ic-nix";
    rev = "20260616";
    sha256 = "sha256-C/er0a+IFaUuq+nffzgmXhy7YFAxl35lDkV2WNZ8Iis=";
  };
  ic-pkgs = import "${ic-nix}/default.nix" { inherit pkgs; };
  moc = ic-pkgs.motoko.moc;
  vessel = ic-pkgs.utils.vessel;

  dhall-to-nix = file:
    import (stdenv.mkDerivation {
      name = "${builtins.baseNameOf file}.nix";
      buildCommand = ''
        export XDG_CACHE_HOME="$TMPDIR/dhall-cache";
        dhall-to-nix <<< "${file}" > $out
      '';
      buildInputs = [ dhall-nix ];
    });

  moc-flags = builtins.concatStringsSep " " (builtins.builtins.map (pkg:
    "--package ${pkg.name} ${
      builtins.fetchGit {
        url = pkg.repo;
        rev = pkg.version;
      }
    }/src") (dhall-to-nix ./package-set.dhall));
in stdenv.mkDerivation {
  version = "0.1.0";
  pname = "ic-logger";
  buildInputs = [ moc vessel ];
  src = lib.cleanSourceWith (rec {
    src = ./.;
    filter = path: type:
      let relPath = lib.removePrefix (toString src + "/") (toString path);
      in lib.any (prefix: lib.hasPrefix prefix relPath) [
        "Makefile"
        "src"
        "test"
      ];
  });
  configurePhase = "mkdir .vessel";
  buildPhase = "make test MOC_FLAGS='${moc-flags}'";
  installPhase = "mkdir -p $out/src && cp -r src/* $out/src/";
}
