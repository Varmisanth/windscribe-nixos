{
  pkgs,
  qt6,
  windscribeQt6ct,
}:
let
  inherit (pkgs) callPackage;
  advobfuscator = callPackage ./pkgs/deps/advobfuscator.nix { };
  cmrc = callPackage ./pkgs/deps/cmrc.nix { };
  cppBase64 = callPackage ./pkgs/deps/cpp-base64.nix { };
  skyrUrl = callPackage ./pkgs/deps/skyr-url.nix { };
  windscribeAmneziawg = callPackage ./pkgs/protocols/amneziawg.nix { };
  windscribeCtrld = callPackage ./pkgs/protocols/ctrld.nix { };
  windscribeCurl = callPackage ./pkgs/crypto/curl.nix {
    inherit windscribeOpenssl windscribeNgtcp2;
  };
  windscribeNgtcp2 = callPackage ./pkgs/crypto/ngtcp2.nix {
    inherit windscribeOpenssl;
  };
  windscribeNmcli = callPackage ./pkgs/deps/nmcli.nix { };
  windscribeOpenssl = callPackage ./pkgs/crypto/openssl.nix { };
  windscribeOpenvpn = callPackage ./pkgs/protocols/openvpn.nix {
    inherit windscribeOpenssl windscribePkcs11helper;
  };
  windscribePkcs11helper = callPackage ./pkgs/crypto/pkcs11-helper.nix {
    inherit windscribeOpenssl;
  };
  windscribeQtPlugins = callPackage ./pkgs/app/qt-plugins.nix { inherit qt6; };
  windscribeWsnet = callPackage ./pkgs/deps/wsnet.nix { };
  windscribeWstunnel = callPackage ./pkgs/protocols/wstunnel.nix { };
in
callPackage ./pkgs/app/desktop-app.nix {
  inherit qt6 windscribeQt6ct;
  inherit
    advobfuscator
    cmrc
    cppBase64
    skyrUrl
    windscribeAmneziawg
    windscribeCtrld
    windscribeCurl
    windscribeNmcli
    windscribeOpenssl
    windscribeOpenvpn
    windscribeQtPlugins
    windscribeWsnet
    windscribeWstunnel
    ;
}
