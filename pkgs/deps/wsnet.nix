{
  lib,
  applyPatches,
  fetchFromGitHub,
  dos2unix,
}:
(applyPatches {
  src = fetchFromGitHub {
    owner = "Windscribe";
    repo = "wsnet";
    rev = "1.5.20";
    hash = "sha256-2PGaoE0p3kr50rdVtvUnG5qdYERBuF5LF88qboxLZgc=";
  };
  nativeBuildInputs = [ dos2unix ];
  prePatch = ''
    dos2unix CMakeLists.txt
  '';
  patches = [ ./openssl-targets.patch ];
}).overrideAttrs
  (
    _: _: {
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
