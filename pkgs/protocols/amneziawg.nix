{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "amneziawg-go";
  version = "0.2.16";
  src = fetchFromGitHub {
    owner = "amnezia-vpn";
    repo = "amneziawg-go";
    rev = "v${finalAttrs.version}";
    hash = "sha256-JGmWMPVgereSZmdHUHC7ZqWCwUNfxfj3xBf/XDDHhpo=";
  };
  vendorHash = "sha256-ZO8sLOaEY3bii9RSxzXDTCcwlsQEYmZDI+X1WPXbE9c=";
  subPackages = [ "." ];
  doCheck = false;
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=v${finalAttrs.version}"
  ];
  meta = {
    description = "AmneziaWG VPN protocol";
    homepage = "https://github.com/amnezia-vpn/amneziawg-go";
    license = lib.licenses.mit;
    mainProgram = "amneziawg-go";
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.unix;
  };
})
