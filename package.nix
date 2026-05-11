{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs) callPackage;
  advobfuscator = callPackage ./pkgs/deps/advobfuscator.nix { };
  cmrc = callPackage ./pkgs/deps/cmrc.nix { };
  cppBase64 = callPackage ./pkgs/deps/cpp-base64.nix { };
  skyrUrl = callPackage ./pkgs/deps/skyr-url.nix { };
  windscribeWsnet = callPackage ./pkgs/deps/wsnet.nix { };
  windscribeOpenssl = callPackage ./pkgs/crypto/openssl.nix { };
  windscribeNgtcp2 = callPackage ./pkgs/crypto/ngtcp2.nix { inherit windscribeOpenssl; };
  windscribePkcs11helper = callPackage ./pkgs/crypto/pkcs11-helper.nix { inherit windscribeOpenssl; };
  windscribeCurl = callPackage ./pkgs/crypto/curl.nix {
    inherit windscribeOpenssl windscribeNgtcp2;
  };
  windscribeAmneziawg = callPackage ./pkgs/protocols/amneziawg.nix { };
  windscribeCtrld = callPackage ./pkgs/protocols/ctrld.nix { };
  windscribeOpenvpn = callPackage ./pkgs/protocols/openvpn.nix {
    inherit windscribeOpenssl windscribePkcs11helper;
  };
  windscribeWstunnel = callPackage ./pkgs/protocols/wstunnel.nix { };
  windscribeQtPlugins = callPackage ./pkgs/app/qt-plugins.nix { };
in
callPackage ./pkgs/app/desktop-app.nix {
  inherit
    advobfuscator
    cmrc
    cppBase64
    skyrUrl
    windscribeAmneziawg
    windscribeCtrld
    windscribeCurl
    windscribeOpenssl
    windscribeOpenvpn
    windscribeQtPlugins
    windscribeWsnet
    windscribeWstunnel
    ;
}
