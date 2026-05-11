{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cpp-base64";
  version = "2.rc.08";
  src = fetchFromGitHub {
    owner = "ReneNyffenegger";
    repo = "cpp-base64";
    rev = "V${finalAttrs.version}";
    hash = "sha256-6O0nmrC4pnzN4R3TOLCd+8cyje/n8mpCXX4lDYlXnHE=";
  };
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm644 base64.h $out/include/cpp-base64/base64.h
    install -Dm644 base64.cpp $out/include/cpp-base64/base64.cpp
    runHook postInstall
  '';
  meta = {
    description = "base64 encoding and decoding with c++";
    homepage = "https://github.com/ReneNyffenegger/cpp-base64";
    license = lib.licenses.zlib;
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.all;
  };
})
