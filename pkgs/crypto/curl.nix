{
  autoconf,
  automake,
  curl,
  fetchFromGitHub,
  libtool,
  windscribeNgtcp2,
  windscribeOpenssl,
}:
(curl.override {
  openssl = windscribeOpenssl;
  ngtcp2 = windscribeNgtcp2;
}).overrideAttrs
  (
    finalAttrs: old: {
      pname = "windscribe-curl";
      version = "8.19.0";
      src = fetchFromGitHub {
        owner = "curl";
        repo = "curl";
        rev = "curl-${builtins.replaceStrings [ "." ] [ "_" ] finalAttrs.version}";
        hash = "sha256-iMu8pD80OTrYwTtXffC9e1W4Bj6e7wPzVlE3ZDFVBxA=";
      };
      patches = [ ./super-padding.patch ];
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        autoconf
        automake
        libtool
      ];
      postPatch = "";
      preConfigure = ''
        autoreconf -fi
        substituteInPlace configure --replace '/usr/bin' '/no-such-path'
        rm -f src/tool_hugehelp.c
        patchShebangs scripts
      '';
      postInstall = (old.postInstall or "") + ''
        install -Dm644 ${./curl-config.cmake.in} $dev/lib/cmake/CURL/CURLConfig.cmake
        substituteInPlace $dev/lib/cmake/CURL/CURLConfig.cmake \
          --replace '@dev@' "$dev" \
          --replace '@out@' "$out"
      '';
      meta = old.meta // {
        description = "A command line tool and library for transferring data with URL syntax";
        maintainers = old.meta.maintainers ++ [
          (import ../../maintainers.nix).varmisanth
        ];
      };
    }
  )
