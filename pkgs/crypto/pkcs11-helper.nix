{ pkcs11helper, windscribeOpenssl }:
(pkcs11helper.override { openssl = windscribeOpenssl; }).overrideAttrs (
  finalAttrs: old: {
    patches = (old.patches or [ ]) ++ [ ./opaque-asn1.patch ];
    meta = old.meta // {
      description = "Library that simplifies the interaction with PKCS#11 providers for end-user applications using a simple API and optional OpenSSL engine";
      maintainers = (old.meta.maintainers or [ ]) ++ [
        (import ../../maintainers.nix).varmisanth
      ];
    };
  }
)
