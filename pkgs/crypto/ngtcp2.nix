{ ngtcp2, windscribeOpenssl }:
(ngtcp2.override { openssl = windscribeOpenssl; }).overrideAttrs (
  _: old: {
    meta = old.meta // {
      maintainers = old.meta.maintainers ++ [
        (import ../../maintainers.nix).varmisanth
      ];
    };
  }
)
