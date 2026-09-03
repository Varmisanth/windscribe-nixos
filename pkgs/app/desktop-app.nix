{
  lib,
  stdenv,
  fetchFromGitHub,
  acl,
  advobfuscator,
  alsa-lib,
  autoPatchelfHook,
  boost188,
  c-ares,
  cmake,
  cmrc,
  coreutils,
  cppBase64,
  ethtool,
  gawk,
  gnugrep,
  gnused,
  gtest,
  iproute2,
  iptables,
  iputils,
  iw,
  kmod,
  libpulseaudio,
  miniaudio,
  ninja,
  nlohmann_json,
  pkg-config,
  qt6,
  range-v3,
  rapidjson,
  skyrUrl,
  spdlog,
  systemd,
  tl-expected,
  util-linux,
  writeText,
  windscribeAmneziawg,
  windscribeCtrld,
  windscribeCurl,
  windscribeNmcli,
  windscribeOpenssl,
  windscribeOpenvpn,
  windscribeQt6ct,
  windscribeQtPlugins,
  windscribeWsnet,
  windscribeWstunnel,
}:
let
  qtConf = writeText "qt.conf" ''
    [Paths]
    Plugins = plugins
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
    kmod
    windscribeNmcli
    systemd
    util-linux
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "windscribe";
  version = "2.24.12";
  src = fetchFromGitHub {
    owner = "Windscribe";
    repo = "Desktop-App";
    rev = "v${finalAttrs.version}";
    hash = "sha256-RiSpysVSrzhWtTgkQmspQ/Hj2cFQLIyjEtfoT7YhM1Q=";
  };
  patches = [
    ./build.patch
    ./network.patch
    ./settings.patch
    ./engine-overlay.patch
    ./autostart.patch
    ./updater.patch
  ];
  nativeBuildInputs = [
    autoPatchelfHook
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    acl
    advobfuscator
    alsa-lib
    boost188
    c-ares
    cmrc
    cppBase64
    gtest
    libpulseaudio
    miniaudio
    nlohmann_json
    qt6.qtbase
    qt6.qtimageformats
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
    windscribeOpenssl.out
  ];
  env = {
    NIX_CFLAGS_COMPILE = "-I${miniaudio.dev}/include/miniaudio";
    NIX_LDFLAGS = "-lcares";
  };
  preConfigure = ''
    cp ${vcpkgStub} cmake/vcpkg.cmake
    mkdir -p build-libs/windscribe
    substituteInPlace cmake/integrations/gui.cmake \
      --replace-fail 'Widgets Network LinguistTools Test' 'Widgets Network Svg WaylandClient LinguistTools Test'
    substituteInPlace cmake/integrations/windscribe.cmake \
      --replace-fail '/opt/windscribe' "$out/opt/windscribe"
    substituteInPlace src/client/CMakeLists.txt \
      --replace-fail 'Qt6::Network' 'Qt6::Network OpenSSL::SSL' \
      --replace-fail 'qt_import_plugins(''${WS_APP_TARGET} INCLUDE Qt6::QWaylandIntegrationPlugin' 'find_package(Qt6QWaylandIntegrationPlugin REQUIRED)
    qt_import_plugins(''${WS_APP_TARGET} INCLUDE Qt6::QWaylandIntegrationPlugin'
    substituteInPlace src/helper/linux/CMakeLists.txt \
      --replace-fail 'OpenSSL::Crypto' 'OpenSSL::Crypto OpenSSL::SSL'
  '';
  cmakeFlags = [
    "-DBUILD_DEB=OFF"
    "-DBUILD_INSTALLER=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_POLICY_DEFAULT_CMP0167=NEW"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DFETCHCONTENT_SOURCE_DIR_WSNET=${windscribeWsnet}"
    "-DOPENSSL_CRYPTO_LIBRARY=${windscribeOpenssl.out}/lib/libcrypto.so"
    "-DOPENSSL_INCLUDE_DIR=${windscribeOpenssl.dev}/include"
    "-DOPENSSL_SSL_LIBRARY=${windscribeOpenssl.out}/lib/libssl.so"
    "-DOPENSSL_USE_STATIC_LIBS=FALSE"
    "-DQt6QWaylandIntegrationPlugin_DIR=${qt6.qtwayland}/lib/cmake/Qt6Gui"
    "-DWINDSCRIBE_OPENSSL_INCLUDE_DIR=${windscribeOpenssl.dev}/include"
    "-DWINDSCRIBE_OPENSSL_LIB_DIR=${windscribeOpenssl.out}/lib"
  ];
  postInstall = ''
    mkdir -p $out/opt/windscribe $out/bin
    mv $out/Windscribe $out/helper $out/opt/windscribe/
    ln -s ${windscribeAmneziawg}/bin/amneziawg-go $out/opt/windscribe/windscribeamneziawg
    ln -s ${windscribeCtrld}/bin/ctrld $out/opt/windscribe/windscribectrld
    ln -s ${windscribeOpenvpn}/bin/openvpn $out/opt/windscribe/windscribeopenvpn
    ln -s ${windscribeWstunnel}/bin/wstunnel $out/opt/windscribe/windscribewstunnel
    cp -r $NIX_BUILD_TOP/source/src/installer/windscribe/linux/opt/windscribe/scripts $out/opt/windscribe/
    for s in $out/opt/windscribe/scripts/*; do
      chmod +x "$s"
      wrapProgram "$s" --prefix PATH : ${scriptPath}
    done
    ln -s ../opt/windscribe/Windscribe $out/bin/Windscribe
    ln -s ${windscribeQtPlugins} $out/opt/windscribe/plugins
    cp ${qtConf} $out/opt/windscribe/qt.conf
    install -Dm644 $NIX_BUILD_TOP/source/src/client/client-common/licenses/open_source_licenses.txt $out/opt/windscribe/open_source_licenses.txt
    install -Dm644 $NIX_BUILD_TOP/source/src/installer/gui/linux/overlay/usr/share/applications/windscribe.desktop $out/share/applications/windscribe.desktop
    substituteInPlace $out/share/applications/windscribe.desktop \
      --replace-fail '/opt/windscribe/Windscribe' 'Windscribe'
    cp -r $NIX_BUILD_TOP/source/src/installer/gui/linux/overlay/usr/share/icons $out/share/
  '';
  qtWrapperArgs = [
    "--prefix QT_PLUGIN_PATH : ${windscribeQt6ct}/lib/qt-6/plugins"
    "--prefix PATH : ${
      lib.makeBinPath [
        coreutils
        ethtool
        gawk
        gnugrep
        gnused
        iproute2
        iputils
        iw
        windscribeNmcli
      ]
    }"
    "--set-default QT_QPA_PLATFORMTHEME qt6ct"
  ];
  passthru.nmcli = windscribeNmcli;
  meta = {
    description = "Windscribe VPN desktop client";
    homepage = "https://github.com/Windscribe/Desktop-App";
    license = lib.licenses.gpl2Only;
    mainProgram = "Windscribe";
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.linux;
  };
})
