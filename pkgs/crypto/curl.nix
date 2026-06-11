{
  fetchFromGitHub,
  autoconf,
  automake,
  curl,
  libssh2,
  libtool,
  windscribeNgtcp2,
  windscribeOpenssl,
}:
(curl.override {
  libssh2 = libssh2.override { openssl = windscribeOpenssl; };
  ngtcp2 = windscribeNgtcp2;
  openssl = windscribeOpenssl;
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
      patches = [
        ./super-large-padding-extension.patch
        ./legacy-ec-point-formats.patch
      ];
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        autoconf
        automake
        libtool
      ];
      postPatch = "";
      preConfigure = ''
        autoreconf -fi
        substituteInPlace configure --replace-fail '/usr/bin' '/no-such-path'
        rm -f src/tool_hugehelp.c
        patchShebangs scripts
      '';
      postInstall = (old.postInstall or "") + ''
        install -Dm644 ${./curl-config.cmake.in} $dev/lib/cmake/CURL/CURLConfig.cmake
        substituteInPlace $dev/lib/cmake/CURL/CURLConfig.cmake \
          --replace-fail '@dev@' "$dev" \
          --replace-fail '@out@' "$out"
      '';
      meta = old.meta // {
        description = "Command line tool and library for transferring data with URL syntax";
        maintainers = old.meta.maintainers ++ [
          (import ../../maintainers.nix).varmisanth
        ];
      };
    }
  )
