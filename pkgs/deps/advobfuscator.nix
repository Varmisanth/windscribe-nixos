{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "advobfuscator";
  version = "0-unstable-2020-06-26";
  src = fetchFromGitHub {
    owner = "andrivet";
    repo = "ADVobfuscator";
    rev = "1852a0eb75b03ab3139af7f938dfb617c292c600";
    hash = "sha256-qleFYWPmCYHHtBO3Op3e8T6fxmC/3KwpatcQ8keiiz8=";
  };
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/include
    cp -r Lib $out/include/Lib
    runHook postInstall
  '';
  meta = {
    description = "Obfuscation library based on C++20 and metaprogramming";
    homepage = "https://github.com/andrivet/ADVobfuscator";
    license = lib.licenses.bsd3Clear;
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.all;
  };
}
