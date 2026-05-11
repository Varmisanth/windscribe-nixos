{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "windscribe-wstunnel";
  version = "1.0.5";
  src = fetchFromGitHub {
    owner = "Windscribe";
    repo = "wstunnel";
    rev = finalAttrs.version;
    hash = "sha256-sLZMcPZdl4U3+b4RWX8d80e6TCyIgwSQlFTdX1EbsII=";
  };
  vendorHash = "sha256-x4TxnSLs1FV09UNx01QavAUZYQjfON2Rp+o7kX0Ki5k=";
  subPackages = [ "." ];
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=v${finalAttrs.version}"
  ];
  meta = {
    description = "Tunnel proxy to wrap  OpenVPN TCP traffic in to websocket or regular TCP traffic as a means to bypass OpenVPN blocks";
    homepage = "https://github.com/Windscribe/wstunnel";
    license = lib.licenses.gpl3Only;
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    mainProgram = "wstunnel";
    platforms = lib.platforms.unix;
  };
})
