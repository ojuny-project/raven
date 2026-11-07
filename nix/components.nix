{
  lib,
  pkgs,
  pkgsCross,
  src,
}:

let
  inherit (pkgs) fetchurl;

  mingw64 = pkgsCross.mingwW64.stdenv.cc;
  mingw32 = pkgsCross.mingw32.stdenv.cc;

  mingwHeadersSource = fetchurl {
    name = "mingw-w64-14.0.0.tar.bz2";
    url = "mirror://sourceforge/mingw-w64/mingw-w64-v14.0.0.tar.bz2";
    hash = "sha256-bq+SHZ65h9OCCzZOqXdbwZuWXsgUkLb91xZSbCjhmVw=";
  };

  mingwHeaders = pkgs.runCommand "mingw-w64-headers" {
    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.bzip2
    ];
  } ''
    mkdir -p $out
    tar -xjf ${mingwHeadersSource} -C $TMPDIR
    cp -a $TMPDIR/mingw-w64-v14.0.0/mingw-w64-headers/include $out/include
  '';

  reactos = fetchurl {
    name = "reactos-source.tar.gz";
    url = "https://codeload.github.com/reactos/reactos/tar.gz/dacf2a6c47fa562799f9c8a41ab6d5c558556558";
    hash = "sha256-U3O7u2BUHLKkngrLUzYOEhjU9dVsMfkYezQbn8Ftqmk=";
  };

  sqliteArchive = fetchurl {
    name = "sqlite-amalgamation-3540100.zip";
    url = "https://www.sqlite.org/2026/sqlite-amalgamation-3540100.zip";
    hash = "sha256-CpyONDUtrUYAaqgoNtU4O/+dxryc5aYFU8Baow5q0fk=";
  };

  vkd3dArchive = fetchurl {
    name = "vkd3d-proton-3.0.1.tar.zst";
    url = "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v3.0.1/vkd3d-proton-3.0.1.tar.zst";
    hash = "sha256-PPIxVSKvXkNgXvbTxB2tkThwQL+XGZk08/erdsqqLww=";
  };

  npp = fetchurl {
    name = "npp.zip";
    url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.6/npp.8.7.6.portable.x64.zip";
    hash = "sha256-iUe73zuH9Gbeo5zKsvmSF3oTJASzkHpmmkSDSE/Gkcw=";
  };

  sqliteTools = fetchurl {
    name = "sqlite.zip";
    url = "https://www.sqlite.org/2025/sqlite-tools-win-x64-3500400.zip";
    hash = "sha256-jOGDR+qGoc5l8ztTPS8UTY0SNxQFKfv4GFdMoR+hOtU=";
  };

  busybox = fetchurl {
    name = "busybox";
    url = "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox";
    hash = "sha256-bhI+fzICqMHpsflNiUFYCiUTU4K5no0+NPuFi7oxE0g=";
  };

  cert =
    name: url: hash:
    fetchurl {
      inherit
        name
        url
        hash
        ;
    };

  roots = pkgs.runCommand "raven-roots" { } ''
    mkdir -p $out
    cp ${cert "MicrosoftRootAuthority.crt" "http://www.microsoft.com/pki/certs/MicrosoftRootAuthority.crt" "sha256-84QG5UDXqdkMtKlHkplkD/tt+eIk7MegHA2VWNja130="} $out/MicrosoftRootAuthority.crt
    cp ${cert "MicrosoftRootCert.crt" "http://www.microsoft.com/pki/certs/MicrosoftRootCert.crt" "sha256-iF3mTDQOPqcGWPAeEUX5V/zaJ6q+6hq5+qn9sBAtQHc="} $out/MicrosoftRootCert.crt
    cp ${cert "MicRooCerAut_2010-06-23.crt" "http://www.microsoft.com/pki/certs/MicRooCerAut_2010-06-23.crt" "sha256-31Rb+RmiQ5w2mDtUzfyQPfpPN9OZbY2EtMMe7G88Fj4="} $out/MicRooCerAut_2010-06-23.crt
    cp ${cert "MicRooCerAut2011_2011_03_22.crt" "http://www.microsoft.com/pki/certs/MicRooCerAut2011_2011_03_22.crt" "sha256-hH32p4SXlD8n/HLrk/mmNzIKArVh0KkbCeh6eAftfGE="} $out/MicRooCerAut2011_2011_03_22.crt
  '';

  fixtures = pkgs.runCommand "raven-fixture-downloads" { } ''
    mkdir -p $out/downloads
    cp ${npp} $out/downloads/npp.zip
    cp ${sqliteTools} $out/downloads/sqlite.zip
    cp ${busybox} $out/downloads/busybox
  '';

  scriptComponent =
    {
      pname,
      script,
      arch ? null,
      nativeBuildInputs ? [ ],
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname;
      version = "unstable";
      inherit src;

      dontUnpack = true;
      dontInstall = true;

      nativeBuildInputs = [ pkgs.python3 ] ++ nativeBuildInputs;

      buildPhase = ''
        runHook preBuild
        mkdir -p $out
        python3 ${src}/scripts/${script} --output $out ${
          if arch == null then "" else "--arch ${arch}"
        }
        runHook postBuild
      '';
    };

  controls64 = scriptComponent {
    pname = "raven-controls64";
    script = "provision-controls.py";
    arch = "x64";
    nativeBuildInputs = [ mingw64 ];
  };

  controls32 = scriptComponent {
    pname = "raven-controls32";
    script = "provision-controls.py";
    arch = "x86";
    nativeBuildInputs = [ mingw32 ];
  };

  rtl = scriptComponent {
    pname = "raven-rtl";
    script = "provision-rtl.py";
    nativeBuildInputs = [ mingw64 ];
  };

  sqlite = pkgs.stdenv.mkDerivation {
    pname = "raven-winsqlite3";
    version = "3.54.1";
    inherit src;

    dontUnpack = true;
    dontInstall = true;

    nativeBuildInputs = [ pkgs.python3 mingw64 ];

    buildPhase = ''
      runHook preBuild
      mkdir -p $out
      python3 ${src}/scripts/provision-sqlite.py \
        --output $out \
        --archive ${sqliteArchive}
      runHook postBuild
    '';
  };

  installer =
    arch:
    let
      cross = if arch == "x64" then mingw64 else mingw32;
      triple = if arch == "x64" then "x86_64-w64-mingw32" else "i686-w64-mingw32";
    in
    pkgs.stdenv.mkDerivation {
      pname = "raven-installer-${arch}";
      version = "unstable";
      inherit src;

      dontUnpack = true;
      dontInstall = true;

      nativeBuildInputs = [
        pkgs.python3
        pkgs.clang
        pkgs.bison
        pkgs.patch
        pkgs.findutils
        pkgs.wine64Packages.minimal
        cross
      ];

      buildPhase = ''
        runHook preBuild
        mkdir -p $out
        cp -a ${src}/scripts $TMPDIR/raven-scripts
        chmod -R u+w $TMPDIR/raven-scripts

        mkdir -p $TMPDIR/bin
        cat > $TMPDIR/bin/${triple}-gcc <<EOF
#!/bin/sh
exec ${cross}/bin/${triple}-gcc -Wno-error=incompatible-pointer-types -Wno-error=format-security "\$@"
EOF
        chmod +x $TMPDIR/bin/${triple}-gcc
        export PATH="$TMPDIR/bin:$PATH"

        cat > $TMPDIR/mx-clsid.h <<'CLSID_EOF'
#ifndef RAVEN_MX_CLSID_H
#define RAVEN_MX_CLSID_H
#define INITGUID
#include <guiddef.h>
DEFINE_GUID(GUID_NULL, 0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
DEFINE_GUID(CLSID_FreeThreadedDOMDocument60, 0x88d96a06, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
DEFINE_GUID(CLSID_XSLTemplate60, 0x88d96a08, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
DEFINE_GUID(CLSID_SAXXMLReader60, 0x88d96a0c, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
DEFINE_GUID(CLSID_SAXAttributes60, 0x88d96a0e, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
DEFINE_GUID(CLSID_MXXMLWriter60, 0x88d96a0f, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
DEFINE_GUID(CLSID_MXNamespaceManager60, 0x88d96a11, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
DEFINE_GUID(CLSID_XMLHTTP60, 0x88d96a0a, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
DEFINE_GUID(CLSID_ServerXMLHTTP60, 0x88d96a0b, 0xf192, 0x11d4, 0xa6, 0x5f, 0x00, 0x40, 0x96, 0x32, 0x51, 0xe5);
#endif
CLSID_EOF
        export MSXML3_COMPAT_HEADER=$TMPDIR/mx-clsid.h

        export MINGW_HEADERS=${mingwHeaders}/include
        export MINGW_INCLUDE=${mingwHeaders}/include
        test -f "$MINGW_HEADERS/msxml2.h"
        test -f "$MINGW_INCLUDE/propkey.h"

        substituteInPlace $TMPDIR/raven-scripts/provision-installer.py \
          --replace-fail 'repo = Path(__file__).resolve().parents[1]' 'repo = Path(os.environ["RAVEN_REPO_ROOT"])' \
          --replace-fail 'headers = Path("/usr") / triple / "include"' 'headers = Path(os.environ["MINGW_HEADERS"])' \
          --replace-fail 'Path("/usr/share/mingw-w64/include/propkey.h")' 'Path(os.environ["MINGW_INCLUDE"]) / "propkey.h"' \
          --replace-fail '-Werror=int-conversion",' '-Werror=int-conversion", "-Wno-error=incompatible-pointer-types",' \
          --replace-fail 'msxml_flags = ["-O2",' 'msxml_flags = ["-include", os.environ["MSXML3_COMPAT_HEADER"], "-O2",' \
          --replace-fail 'run([*widl, "-t", "-T", generated / "tom_library.tlb", own_riched / "tom_library.idl"])' 'run([*widl, "-L", generated, "-t", "-T", generated / "tom_library.tlb", own_riched / "tom_library.idl"])' \


        export RAVEN_REPO_ROOT=${src}
        export PATH="${pkgs.wine64Packages.minimal}/bin:$PATH"
        python3 $TMPDIR/raven-scripts/provision-installer.py \
          --archive ${reactos} \
          --output $out \
          --arch ${arch}
        runHook postBuild
      '';
    };
in
{
  inherit
    reactos
    rtl
    controls64
    controls32
    roots
    sqlite
    fixtures
    ;

  installer64 = installer "x64";
  installer32 = installer "x86";

  dxvk64 = pkgs.dxvk.passthru.dxvk64;
  dxvk32 = pkgs.dxvk.passthru.dxvk32;

  vkd3d = pkgs.runCommand "raven-vkd3d-proton-3.0.1" {
    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.zstd
    ];
  } ''
    mkdir -p $out
    tar --zstd -xf ${vkd3dArchive} -C $out --strip-components=1
    mv $out/x64 $out/pe64
    mv $out/x86 $out/pe32
  '';

  libpng = pkgs.libpng;
  fonts = "${pkgs.liberation_ttf_v2}/share/fonts/truetype";

  skia = null;
}
