{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cmrc";
  version = "2.0.1";
  src = fetchFromGitHub {
    owner = "vector-of-bool";
    repo = "cmrc";
    rev = finalAttrs.version;
    hash = "sha256-++16WAs2K9BKk8384yaSI/YD1CdtdyXVBIjGhqi4JIk=";
  };
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm644 CMakeRC.cmake $out/share/cmake/CMakeRC/CMakeRCConfig.cmake
    runHook postInstall
  '';
  meta = {
    description = "A Resource Compiler in a Single CMake Script";
    homepage = "https://github.com/vector-of-bool/cmrc";
    license = lib.licenses.mit;
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.all;
  };
})
