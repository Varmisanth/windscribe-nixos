{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "ctrld";
  version = "1.5.0";
  src = fetchFromGitHub {
    owner = "Control-D-Inc";
    repo = "ctrld";
    rev = "v${finalAttrs.version}";
    hash = "sha256-KrkEI07wfddDGmor2VT3I5gGmeZX75UGLZl++a6sE+c=";
  };
  vendorHash = "sha256-rsRlInNk6/C9DzJLbCoQSbV1exGfstbTxE8qitKmZ0c=";
  subPackages = [ "cmd/ctrld" ];
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=v${finalAttrs.version}"
  ];
  meta = {
    description = "A highly configurable, multi-protocol DNS forwarding proxy";
    homepage = "https://github.com/Control-D-Inc/ctrld";
    license = lib.licenses.mit;
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.unix;
  };
})
