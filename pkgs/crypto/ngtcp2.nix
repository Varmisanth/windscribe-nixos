{ ngtcp2, windscribeOpenssl }:
(ngtcp2.override { openssl = windscribeOpenssl; }).overrideAttrs (
  finalAttrs: old: {
    meta = old.meta // {
      maintainers = (old.meta.maintainers or [ ]) ++ [
        (import ../../maintainers.nix).varmisanth
      ];
    };
  }
)
