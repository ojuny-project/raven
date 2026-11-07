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

  zlibSource = fetchurl {
    name = "zlib-1.3.1-source.tar.gz";
    url = "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz";
    sha256 = "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23";
  };

  libjpegSource = fetchurl {
    name = "libjpeg-10-source.tar.gz";
    url = "https://www.ijg.org/files/jpegsrc.v10.tar.gz";
    sha256 = "8b9eaa13242690ebd03e1728ab1edf97a81a78ed6e83624d493655f31ac95ab5";
  };

  libtiffSource = fetchurl {
    name = "libtiff-4.7.1-source.tar.gz";
    url = "https://download.osgeo.org/libtiff/tiff-4.7.1.tar.gz";
    sha256 = "f698d94f3103da8ca7438d84e0344e453fe0ba3b7486e04c5bf7a9a3fabe9b69";
  };

  libxml2Source = fetchurl {
    name = "libxml2-2.12.8-source.tar.xz";
    url = "https://download.gnome.org/sources/libxml2/2.12/libxml2-2.12.8.tar.xz";
    sha256 = "43ad877b018bc63deb2468d71f95219c2fac196876ef36d1bee51d226173ec93";
  };

  libxsltSource = fetchurl {
    name = "libxslt-1.1.42-source.tar.xz";
    url = "https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.42.tar.xz";
    sha256 = "85ca62cac0d41fc77d3f6033da9df6fd73d20ea2fc18b0a3609ffb4110e1baeb";
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
        cp ${zlibSource} $out/zlib-1.3.1-source.tar.gz
        cp ${libjpegSource} $out/libjpeg-10-source.tar.gz
        cp ${libtiffSource} $out/libtiff-4.7.1-source.tar.gz
        cp ${libxml2Source} $out/libxml2-2.12.8-source.tar.xz
        cp ${libxsltSource} $out/libxslt-1.1.42-source.tar.xz
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
          --replace-fail '-Werror=int-conversion",' '-Werror=int-conversion", "-Wno-error=incompatible-pointer-types",' \
          --replace-fail 'msxml_flags = ["-O2",' 'msxml_flags = ["-include", os.environ["MSXML3_COMPAT_HEADER"], "-O2",'


        export RAVEN_REPO_ROOT=${src}
        export PATH="${pkgs.wine64Packages.minimal}/bin:$PATH"
        python3 $TMPDIR/raven-scripts/provision-installer.py \
          --output $out \
          --arch ${arch}
        runHook postBuild
      '';
    };

  skiaSource = pkgs.fetchgit {
    url = "https://skia.googlesource.com/skia.git";
    rev = "a21aae83d6e4e3da284100a30f0a5eafc443b60f";
    hash = "sha256-ofmQJl6050CmoPpP97QSPVodzh348BdOniBXUF8f1+8=";
  };

  skiaDeps = pkgs.stdenv.mkDerivation {
    pname = "raven-skia-deps";
    version = "a21aae";

    src = skiaSource;

    nativeBuildInputs = [
      pkgs.git
      pkgs.python3
      pkgs.cacert
    ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-ZBOGqU6BC9gRRGeBxthq/oF7MCnwzV+VruIE7R5nr2A=";

    buildPhase = ''
      export HOME=$TMPDIR
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export GIT_SYNC_DEPS_SKIP_EMSDK=1
      git config --global url."https://".insteadOf git://
      sed -i '/thread.start()/a\    thread.join()' tools/git-sync-deps
      python3 tools/git-sync-deps
    '';

    installPhase = ''
      mkdir -p $out
      cp -a . $out/
      find $out -type d -name .git -prune -exec rm -rf {} +
      rm -rf $out/bin $out/tools $out/infra $out/site $out/docs $out/resources
      rm -rf $out/tests $out/testdata $out/bench $out/gm $out/fuzz $out/example
      rm -rf $out/third_party/externals
      find $out -type l -lname '*nix/store*' -delete
      find $out -type f -print0 | xargs -0 -r grep -lZ '/nix/store' | xargs -0 -r rm -f || true
      for hash in "$(basename ${pkgs.bash} | cut -c1-32)" nnm9gdr70ihc6zc9298mzz8jpcgaciql; do
        find $out -type f -print0 | xargs -0 -r grep -lZ "$hash" | xargs -0 -r rm -f || true
        find $out -type l -lname "*$hash*" -delete
      done
    '';
  };

  skia = pkgs.stdenv.mkDerivation {
    pname = "raven-skia";
    version = "a21aae";

    src = skiaDeps;

    nativeBuildInputs = [
      pkgs.gn
      pkgs.ninja
      pkgs.python3
      pkgs.pkg-config
      pkgs.clang
      pkgs.lld
    ];

    buildInputs = [ pkgs.freetype ];

    buildPhase = ''
      mkdir -p out
      cat > out/args.gn <<'EOF'
      is_official_build = true
      is_debug = false
      cc = "clang"
      cxx = "clang++"
      skia_enable_ganesh = false
      skia_enable_graphite = false
      skia_enable_pdf = false
      skia_enable_skottie = false
      skia_enable_svg = false
      skia_enable_tools = false
      skia_use_partition_alloc = false
      skia_use_gl = false
      skia_use_x11 = false
      skia_use_fontconfig = false
      skia_use_freetype = true
      skia_use_harfbuzz = false
      skia_use_icu = false
      skia_use_expat = false
      skia_use_piex = false
      skia_use_wuffs = false
      skia_use_libjpeg_turbo_decode = false
      skia_use_libjpeg_turbo_encode = false
      skia_use_libpng_decode = false
      skia_use_libpng_encode = false
      skia_use_libwebp_decode = false
      skia_use_libwebp_encode = false
      skia_use_zlib = false
      skia_use_perfetto = false
      skia_enable_fontmgr_empty = true
      skia_enable_fontmgr_custom_empty = true
      skia_use_system_freetype2 = true
      EOF

      gn gen out
      ninja -C out skia
    '';

    installPhase = ''
      mkdir -p $out/lib
      ln -s ${skiaDeps} $out/source
      cp out/libskia.a $out/lib/libskia.a
    '';
  };

  liberationDeb = fetchurl {
    name = "fonts-liberation.deb";
    url = "http://archive.ubuntu.com/ubuntu/pool/main/f/fonts-liberation/fonts-liberation_2.1.5-3build1_all.deb";
    sha256 = "47f156bc945cfc69cf2f2a0c19b8c82b67a685738d3846673462de6a73266e1b";
  };

  dejavuArchive = fetchurl {
    name = "dejavu-fonts-ttf-2.37.tar.bz2";
    url = "https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2";
    sha256 = "fa9ca4d13871dd122f61258a80d01751d603b4d3ee14095d65453b4e846e17d7";
  };

  fontOutput = pkgs.runCommand "raven-fonts" {
    nativeBuildInputs = [
      (pkgs.python3.withPackages (ps: [ ps.fonttools ]))
      pkgs.gnutar
      pkgs.xz
      pkgs.zstd
      pkgs.git
      pkgs.clang
    ];
  } ''
    mkdir -p $out
    cp ${liberationDeb} $out/fonts-liberation.deb
    cp ${dejavuArchive} $out/dejavu-fonts-ttf-2.37.tar.bz2
    python3 ${src}/scripts/provision-text.py --output $out --fonts-only
    test -f $out/fonts/LiberationSans-Regular.ttf
    test -f $out/fonts/RavenSans-Regular.ttf
  '';
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
  fonts = "${fontOutput}/fonts";

  inherit fontOutput skia skiaDeps;
}
