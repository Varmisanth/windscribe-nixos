{ fetchFromGitHub, openssl }:
openssl.overrideAttrs (
  finalAttrs: old: {
    pname = "windscribe-openssl";
    version = "4.0.0";
    src = fetchFromGitHub {
      owner = "openssl";
      repo = "openssl";
      rev = "openssl-${finalAttrs.version}";
      hash = "sha256-9ls8VFqdprUoet4ch4dwNmMewioNnFRrOtQ2VMuRw4U=";
    };
    patches = [ ./tls-padding.patch ];
    meta = old.meta // {
      description = "General purpose TLS and crypto library";
      maintainers = old.meta.maintainers ++ [
        (import ../../maintainers.nix).varmisanth
      ];
    };
  }
)
