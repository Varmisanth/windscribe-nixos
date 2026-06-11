{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  libcap_ng,
  libnl,
  lz4,
  lzo,
  pkg-config,
  python3,
  windscribeOpenssl,
  windscribePkcs11helper,
}:
stdenv.mkDerivation {
  pname = "windscribe-openvpn";
  version = "2.7.4";
  src = fetchFromGitHub {
    owner = "OpenVPN";
    repo = "openvpn";
    rev = "8e9e91f4caff9a80961f32a1f9eda7e5a489176e";
    hash = "sha256-KYj3TazH6lWUvjI8SCCNSjXv0z12qeNXt4KhqJSYPPU=";
  };
  patches = [
    ./anti-censorship.patch
    ./openvpn-targets.patch
  ];
  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ];
  buildInputs = [
    libcap_ng
    libnl
    lz4
    lzo
    windscribeOpenssl
    windscribePkcs11helper
  ];
  cmakeFlags = [
    "-DUNSUPPORTED_BUILDS=true"
  ];
  meta = {
    description = "Open source VPN daemon";
    homepage = "https://github.com/OpenVPN/openvpn";
    license = lib.licenses.gpl2Only;
    mainProgram = "openvpn";
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.linux;
  };
}
