{
  applyPatches,
  dos2unix,
  fetchFromGitHub,
  lib,
}:
(applyPatches {
  src = fetchFromGitHub {
    owner = "Windscribe";
    repo = "wsnet";
    rev = "1.5.6.3";
    hash = "sha256-1M6Ju36Cc3jIZs+0FQJfqp+LTbFoVihxNdQ7XrfdNes=";
  };
  nativeBuildInputs = [ dos2unix ];
  prePatch = ''
    dos2unix CMakeLists.txt
  '';
  patches = [ ./wsnet-openssl-targets.patch ];
}).overrideAttrs
  (
    finalAttrs: old: {
      meta = {
        description = "Cross-platform C++ networking library for Windscribe VPN clients";
        homepage = "https://github.com/Windscribe/wsnet";
        license = lib.licenses.gpl2Only;
        maintainers = [
          (import ../../maintainers.nix).varmisanth
        ];
        platforms = lib.platforms.unix;
      };
    }
  )
