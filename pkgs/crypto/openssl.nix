{ fetchFromGitHub, openssl }:
openssl.overrideAttrs (
  finalAttrs: old: {
    pname = "windscribe-openssl";
    version = "4.0.1";
    src = fetchFromGitHub {
      owner = "openssl";
      repo = "openssl";
      rev = "openssl-${finalAttrs.version}";
      hash = "sha256-HHz0tUteYhZNIZ/j47VDCshacx8JOII4ldKQ7cV0qp0=";
    };
    patches = (old.patches or [ ]) ++ [
      ./super-large-tls-padding-extension.patch
    ];
    postPatch = "patchShebangs Configure";
    doCheck = false;
    meta = old.meta // {
      description = "General purpose TLS and crypto library";
      maintainers = old.meta.maintainers ++ [
        (import ../../maintainers.nix).varmisanth
      ];
    };
  }
)
