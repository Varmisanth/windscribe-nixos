{
  runCommand,
  autoPatchelfHook,
  glib,
  gnutls,
  ncurses,
  networkmanager,
  readline,
  systemd,
  util-linux,
}:
runCommand "nmcli-${networkmanager.version}"
  {
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      glib
      gnutls
      ncurses
      readline
      systemd
      util-linux
    ];
    meta = {
      description = "Standalone nmcli with libnm, extracted from NetworkManager";
      inherit (networkmanager.meta) homepage license platforms;
      maintainers = [
        (import ../../maintainers.nix).varmisanth
      ];
      mainProgram = "nmcli";
    };
  }
  ''
    mkdir -p $out/bin $out/lib
    cp ${networkmanager}/bin/nmcli $out/bin/
    cp -d ${networkmanager}/lib/libnm.so* $out/lib/
    addAutoPatchelfSearchPath $out/lib
  ''
