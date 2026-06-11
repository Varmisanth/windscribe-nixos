{
  lib,
  symlinkJoin,
  qt6,
}:
symlinkJoin {
  name = "windscribe-qt-plugins";
  paths = [
    "${qt6.qtbase}/lib/qt-6/plugins"
    "${qt6.qtimageformats}/lib/qt-6/plugins"
    "${qt6.qtsvg}/lib/qt-6/plugins"
    "${qt6.qtwayland}/lib/qt-6/plugins"
  ];
  meta = {
    description = "Merged Qt6 plugin tree for Windscribe";
    maintainers = [
      (import ../../maintainers.nix).varmisanth
    ];
    platforms = lib.platforms.linux;
  };
}
