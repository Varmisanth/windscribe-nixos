{ ngtcp2, windscribeOpenssl }:
(ngtcp2.override { openssl = windscribeOpenssl; }).overrideAttrs (
  _: old: {
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [
      "-DENABLE_LIB_ONLY:BOOL=TRUE"
    ];
    meta = old.meta // {
      maintainers = old.meta.maintainers ++ [
        (import ../../maintainers.nix).varmisanth
      ];
    };
  }
)
