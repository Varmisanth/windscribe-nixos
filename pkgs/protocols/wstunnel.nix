{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "windscribe-wstunnel";
  version = "1.0.6";
  src = fetchFromGitHub {
    owner = "Windscribe";
    repo = "wstunnel";
    rev = "v${finalAttrs.version}";
    hash = "sha256-WGLgZStXzZjseMumxQ2D1UFSdE3xZpYE6g5omPw6swQ=";
  };
  vendorHash = "sha256-Ma9bTnJmQ983Oio1c8T4eC4Sg45y0vGoaRIeKaSVhLM=";
  subPackages = [ "." ];
  ldflags = [
    "-s"
    "-w"
  ];
  meta = {
    description = "Tunnel proxy to wrap OpenVPN TCP traffic into websocket or regular TCP traffic as a means to bypass OpenVPN blocks";
    homepage = "https://github.com/Windscribe/wstunnel";
    license = lib.licenses.gpl3Only;
    mainProgram = "wstunnel";
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.unix;
  };
})
