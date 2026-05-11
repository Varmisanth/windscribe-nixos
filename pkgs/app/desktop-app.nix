{
  lib,
  stdenv,
  fetchFromGitHub,
  writeText,
  autoPatchelfHook,
  cmake,
  ninja,
  pkg-config,
  python3,
  advobfuscator,
  alsa-lib,
  boost186,
  c-ares,
  cmrc,
  coreutils,
  cppBase64,
  gawk,
  gnugrep,
  gnused,
  gtest,
  iproute2,
  iptables,
  libcap_ng,
  libnl,
  libpulseaudio,
  lz4,
  lzo,
  miniaudio,
  networkmanager,
  nlohmann_json,
  qt6,
  range-v3,
  rapidjson,
  skyrUrl,
  spdlog,
  systemd,
  tl-expected,
  util-linux,
  windscribeAmneziawg,
  windscribeCtrld,
  windscribeCurl,
  windscribeOpenssl,
  windscribeOpenvpn,
  windscribeQtPlugins,
  windscribeWsnet,
  windscribeWstunnel,
}:
let
  qtConf = writeText "qt.conf" ''
    [Paths]
    Plugins = plugins
    Qml2Imports = ${qt6.qtdeclarative}/lib/qt-6/qml
  '';
  vcpkgStub = writeText "vcpkg.cmake" ''
    macro(install_vcpkg_dependencies)
    endmacro()
  '';
  scriptPath = lib.makeBinPath [
    coreutils
    gawk
    gnugrep
    gnused
    iproute2
    iptables
    networkmanager
    systemd
    util-linux
  ];
  helperScripts = [
    "cgroups-down"
    "cgroups-up"
    "dns-leak-protect"
    "gai-ipv4-priority"
    "update-network-manager"
    "update-resolv-conf"
    "update-systemd-resolved"
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "windscribe";
  version = "2.22.6";
  src = fetchFromGitHub {
    owner = "Windscribe";
    repo = "Desktop-App";
    rev = "v${finalAttrs.version}";
    hash = "sha256-5LJBgFdS1qIZqJJTadIgeebNQwojSK3IAzt7QDHc4As=";
  };
  patches = [
    ./build.patch
    ./iptables-comment.patch
  ];
  nativeBuildInputs = [
    autoPatchelfHook
    cmake
    ninja
    pkg-config
    python3
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    advobfuscator
    alsa-lib
    boost186
    c-ares
    cmrc
    cppBase64
    gtest
    libcap_ng
    libnl
    libpulseaudio
    lz4
    lzo
    miniaudio
    nlohmann_json
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtimageformats
    qt6.qtshadertools
    qt6.qtsvg
    qt6.qttools
    qt6.qtwayland
    range-v3
    rapidjson
    skyrUrl
    spdlog
    tl-expected
    windscribeCurl
    windscribeOpenssl
  ];
  runtimeDependencies = [
    alsa-lib
    libpulseaudio
  ];
  env = {
    NIX_CFLAGS_COMPILE = "-I${miniaudio.dev}/include/miniaudio";
    NIX_LDFLAGS = "-lcares";
  };
  preConfigure = ''
    cp ${vcpkgStub} cmake/vcpkg.cmake
    substituteInPlace cmake/integrations/windscribe.cmake \
      --replace '/opt/windscribe' "$out/opt/windscribe"
    substituteInPlace src/client/frontend/frontend-common/utils/authchecker_linux.cpp \
      --replace '/usr/bin/pkexec' '/run/wrappers/bin/pkexec'
  '';
  cmakeFlags = [
    "-DBUILD_DEB=OFF"
    "-DBUILD_INSTALLER=OFF"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DFETCHCONTENT_SOURCE_DIR_WSNET=${windscribeWsnet}"
    "-DOPENSSL_CRYPTO_LIBRARY=${windscribeOpenssl.out}/lib/libcrypto.so"
    "-DOPENSSL_INCLUDE_DIR=${windscribeOpenssl.dev}/include"
    "-DOPENSSL_SSL_LIBRARY=${windscribeOpenssl.out}/lib/libssl.so"
    "-DOPENSSL_USE_STATIC_LIBS=FALSE"
    "-DWINDSCRIBE_OPENSSL_INCLUDE_DIR=${windscribeOpenssl.dev}/include"
    "-DWINDSCRIBE_OPENSSL_LIB_DIR=${windscribeOpenssl.out}/lib"
  ];
  postInstall = ''
    mkdir -p $out/opt/windscribe $out/bin
    mv $out/Windscribe $out/helper $out/windscribe-cli $out/windscribe-authhelper $out/opt/windscribe/
    ln -s ${windscribeAmneziawg}/bin/amneziawg-go $out/opt/windscribe/amneziawg
    ln -s ${windscribeCtrld}/bin/ctrld $out/opt/windscribe/ctrld
    ln -s ${windscribeOpenvpn}/bin/openvpn $out/opt/windscribe/windscribeopenvpn
    ln -s ${windscribeWstunnel}/bin/wstunnel $out/opt/windscribe/windscribewstunnel
    cp -r $NIX_BUILD_TOP/source/src/installer/windscribe/linux/opt/windscribe/scripts $out/opt/windscribe/
    chmod +x $out/opt/windscribe/scripts/*
    ${lib.concatMapStringsSep "\n    " (
      s: "wrapProgram $out/opt/windscribe/scripts/${s} --prefix PATH : ${scriptPath}"
    ) helperScripts}
    install -Dm644 $NIX_BUILD_TOP/source/src/installer/windscribe/linux/usr/polkit-1/actions/com.windscribe.authhelper.policy $out/share/polkit-1/actions/com.windscribe.authhelper.policy
    substituteInPlace $out/share/polkit-1/actions/com.windscribe.authhelper.policy \
      --replace '/opt/windscribe/windscribe-authhelper' "$out/opt/windscribe/windscribe-authhelper"
    ln -s ../opt/windscribe/Windscribe $out/bin/Windscribe
    ln -s ../opt/windscribe/windscribe-cli $out/bin/windscribe-cli
    ln -s ${windscribeQtPlugins} $out/opt/windscribe/plugins
    cp ${qtConf} $out/opt/windscribe/qt.conf
    install -Dm644 $NIX_BUILD_TOP/source/src/client/client-common/licenses/open_source_licenses.txt $out/opt/windscribe/open_source_licenses.txt
    install -Dm644 $NIX_BUILD_TOP/source/src/installer/gui/linux/overlay/usr/share/applications/windscribe.desktop $out/share/applications/windscribe.desktop
    substituteInPlace $out/share/applications/windscribe.desktop \
      --replace '/opt/windscribe/Windscribe' 'Windscribe'
    cp -r $NIX_BUILD_TOP/source/src/installer/gui/linux/overlay/usr/share/icons $out/share/
  '';
  meta = {
    description = "Public mirror of the Windscribe VPN desktop client for Windows, Mac and Linux";
    homepage = "https://github.com/Windscribe/Desktop-App";
    license = lib.licenses.gpl2Only;
    mainProgram = "Windscribe";
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.linux;
  };
})
