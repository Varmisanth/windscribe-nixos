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
  }
  ''
    mkdir -p $out/bin $out/lib
    cp ${networkmanager}/bin/nmcli $out/bin/
    cp -d ${networkmanager}/lib/libnm.so* $out/lib/
    addAutoPatchelfSearchPath $out/lib
  ''
