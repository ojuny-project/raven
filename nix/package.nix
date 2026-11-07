{
  lib,
  pkgs,
  withControls ? true,
  withInstaller ? true,
  withGraphics ? true,
  withSqlite ? true,
  withFonts ? true,
  withSkia ? false,
  withTests ? false,
}:

let
  src = lib.cleanSource ../.;

  components = import ./components.nix {
    inherit lib pkgs src;
    pkgsCross = pkgs.pkgsCross;
  };

  version = "0-unstable-2026-11-02";

  mingw64 = pkgs.pkgsCross.mingwW64.stdenv.cc;
  mingw32 = pkgs.pkgsCross.mingw32.stdenv.cc;

  runtimeComponents = [
    "comctl32.dll"
    "raven-user32.dll"
    "raven-shell.dll"
    "raven-dwrite.dll"
    "raven-d2d1.dll"
    "raven-uianimation.dll"
    "ucrtbase.dll"
    "raven-rtl.dll"
    "raven-storage.dll"
    "msi.dll"
    "cabinet.dll"
    "sxs.dll"
    "rpcrt4.dll"
    "msxml3.dll"
    "libpng.dll"
    "libjpeg.dll"
    "libtiff.dll"
    "propsys.dll"
    "mlang.dll"
    "windowscodecs.dll"
    "gdiplus.dll"
    "urlmon.dll"
    "riched20.dll"
    "msftedit.dll"
    "msvfw32.dll"
    "advpack.dll"
    "raven-setupapi.dll"
    "xmllite.dll"
    "atl100.dll"
    "oleaut32.dll"
    "libxslt.dll"
    "mscoree.dll"
    "taskschd.dll"
    "webservices.dll"
    "hlink.dll"
    "raven-accprop.dll"
    "raven-deployment.dll"
    "raven-netlist.dll"
    "raven-uisettings.dll"
    "raven-twinapi.dll"
    "raven-d3d10_1.dll"
    "d3dcompiler_47.dll"
    "winsqlite3.dll"
    "icu.dll"
    "icuuc.dll"
    "icuin.dll"
  ];

  runtimePrograms = [
    "cmd.exe"
    "control.exe"
    "dism.exe"
    "fondue.exe"
    "msiexec.exe"
    "regedit.exe"
    "regsvr32.exe"
    "find.exe"
    "findstr.exe"
    "more.com"
    "sort.exe"
    "where.exe"
    "xcopy.exe"
    "attrib.exe"
    "timeout.exe"
    "choice.exe"
    "whoami.exe"
    "hostname.exe"
    "tasklist.exe"
    "taskkill.exe"
    "reg.exe"
    "rundll32.exe"
  ];

  testFilter = "^(pe_contracts|module_set_contracts|native_(cpu_contracts|memory_contracts|parallel_memory_contracts|parallel_stop_contract|x86_contracts|shared_mapping_contract|provider_contract|launch_arguments_contract|ansi_code_page|hlsl_compiler|update_regions|keyboard_layouts|font_ownership|compatible_bitmap_contract|bitblt_contract|class_info_ownership|window_data_ownership|brush_ownership|exception_contract|object_contract|handle_channel_contract|firmware_memory|string_resource_contract|resource_contract|process_parameters|menu_ownership|extract_icons_contract|png_codec_contract|icon_dib_contract|icon_group_contract|blackonwhite_contract))$";

  raven-unwrapped = pkgs.stdenv.mkDerivation {
    pname = "raven-unwrapped";
    inherit version src;

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.ninja
      pkgs.python3
      pkgs.pkg-config
      pkgs.wayland
      pkgs.libffi
      pkgs.wayland-protocols
      pkgs.clang
      pkgs.lld
      pkgs.openssl
      mingw64
      mingw32
    ];

    buildInputs = [
      pkgs.wayland
      pkgs.libffi
      pkgs.wayland-protocols
      pkgs.libxkbcommon
      pkgs.pixman
      pkgs.libxcb
      pkgs.libX11
      pkgs.libXext
      pkgs.libGL
      pkgs.libGLU
      pkgs.vulkan-loader
      pkgs.vulkan-headers
      pkgs.freetype
      pkgs.openssl
      pkgs.libpng
      pkgs.libpulseaudio
    ];

    preConfigure = ''
      mkdir -p build/testdata/downloads
      cp -a ${components.fixtures}/downloads/. build/testdata/downloads/
      sed -i 's/-mno-stack-arg-probe/-mno-stack-arg-probe -fomit-frame-pointer -momit-leaf-frame-pointer -O0/g' native/CMakeLists.txt
      sed -i '/add_custom_target(vulkan_.*_fixture ALL DEPENDS/ s/ ALL DEPENDS.*/)/' native/CMakeLists.txt
      sed -i '/add_custom_target(cxx_exception_fixtures ALL DEPENDS/ s/ ALL DEPENDS.*/)/' native/CMakeLists.txt
      sed -i '/add_custom_target(gcc_exceptions_fixture ALL DEPENDS/ s/ ALL DEPENDS.*/)/' native/CMakeLists.txt
    '';

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
      "-DRAVEN_VK_XML=${pkgs.vulkan-headers}/share/vulkan/registry/vk.xml"
      "-DRAVEN_VULKAN_CORE_HEADER=${pkgs.vulkan-headers}/include/vulkan/vulkan_core.h"
    ]
    ++ lib.optionals withControls [
      "-DRAVEN_CONTROLS_COMPONENT_DIR=${components.controls64}"
      "-DRAVEN_CONTROLS32_COMPONENT_DIR=${components.controls32}"
      "-DRAVEN_RTL_COMPONENT_PATH=${components.rtl}/raven-rtl.dll"
    ]
    ++ lib.optionals withInstaller [
      "-DRAVEN_INSTALLER_COMPONENT_DIR=${components.installer64}"
      "-DRAVEN_INSTALLER32_COMPONENT_DIR=${components.installer32}"
      "-DRAVEN_ROOT_CERTIFICATE_DIRECTORY=${components.roots}"
    ]
    ++ lib.optionals withGraphics [
      "-DRAVEN_DXVK_PE64_DIR=${components.dxvk64}/bin"
      "-DRAVEN_DXVK_PE32_DIR=${components.dxvk32}/bin"
      "-DRAVEN_VKD3D_PE64_DIR=${components.vkd3d}/pe64"
    ]
    ++ lib.optionals withSqlite [
      "-DRAVEN_SQLITE_COMPONENT_DIR=${components.sqlite}"
    ]
    ++ lib.optionals withSkia [
      "-DRAVEN_SKIA_SOURCE=${components.skia}/source"
      "-DRAVEN_SKIA_LIBRARY=${components.skia}/lib/libskia.a"
      "-DRAVEN_FONT_DIRECTORY=${components.fonts}"
    ];

    doCheck = withTests;

    checkPhase = ''
      runHook preCheck
      export HOME=$TMPDIR/raven-home
      export RAVEN_PREFIX=$TMPDIR/raven-prefix
      mkdir -p "$HOME" "$RAVEN_PREFIX"
      ctest --output-on-failure -j1 -R '${testFilter}'
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall

      runtime="$PWD/native"
      if [ ! -d "$runtime" ]; then
        runtime="$PWD/build/native"
      fi
      mkdir -p $out/libexec/raven/x86 $out/bin

      install -Dm755 "$runtime/raven" $out/libexec/raven/raven
      install -Dm755 "$runtime/raven-bootstrap" $out/libexec/raven/raven-bootstrap

      copy_component() {
        source_dir="$1"
        destination_dir="$2"
        shift 2
        for name in "$@"; do
          if [ -f "$source_dir/$name" ]; then
            install -Dm755 "$source_dir/$name" "$destination_dir/$name"
          fi
        done
      }

      copy_component "$runtime" $out/libexec/raven \
        ${lib.escapeShellArgs runtimeComponents} ${lib.escapeShellArgs runtimePrograms}

      copy_component "$runtime/x86" $out/libexec/raven/x86 \
        ${lib.escapeShellArgs runtimeComponents} ${lib.escapeShellArgs runtimePrograms} ucrtbase32.dll

      if [ -f "$runtime/l_intl.nls" ]; then
        install -Dm644 "$runtime/l_intl.nls" $out/libexec/raven/l_intl.nls
      fi
      if [ -f "$runtime/x86/l_intl.nls" ]; then
        install -Dm644 "$runtime/x86/l_intl.nls" $out/libexec/raven/x86/l_intl.nls
      fi

      mkdir -p $out/libexec/raven/roots
      for certificate in ${components.roots}/*.crt; do
        install -Dm644 "$certificate" $out/libexec/raven/roots/$(basename "$certificate")
      done

      ${lib.optionalString withFonts ''
        mkdir -p $out/libexec/raven/fonts
        for font in ${components.fonts}/Liberation*.ttf; do
          install -Dm644 "$font" $out/libexec/raven/fonts/$(basename "$font")
        done
      ''}

      install -Dm644 ${src}/LICENSE $out/libexec/raven/LICENSE
      install -Dm644 ${src}/LICENSES.md $out/libexec/raven/LICENSES.md
      install -Dm644 ${src}/LICENSES.json $out/libexec/raven/LICENSES.json
      mkdir -p $out/libexec/raven/LICENSES
      for license in ${src}/LICENSES/*; do
        install -Dm644 "$license" $out/libexec/raven/LICENSES/$(basename "$license")
      done

      ln -s ../libexec/raven/raven $out/bin/raven

      runHook postInstall
    '';

    meta = {
      description = "Windows application runtime for Linux";
      homepage = "https://useraven.org";
      license = lib.licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = "raven";
    };

    passthru = {
      inherit components;
    };
  };

  makeRaven =
    {
      extraPkgs ? (_: [ ]),
      extraLibraries ? (_: [ ]),
      extraProfile ? "",
      extraEnv ? { },
      extraBwrapArgs ? [ ],
      privateTmp ? true,
    }:
    import ./fhs.nix { inherit lib pkgs; } {
      inherit
        raven-unwrapped
        extraPkgs
        extraLibraries
        extraProfile
        extraEnv
        extraBwrapArgs
        privateTmp
        ;
      meta = {
        description = "Windows application runtime for Linux";
        homepage = "https://useraven.org";
        license = lib.licenses.gpl3Plus;
        platforms = [ "x86_64-linux" ];
        mainProgram = "raven";
        sourceProvenance = [
          lib.sourceTypes.fromSource
          lib.sourceTypes.binaryNativeCode
        ];
      };
      passthru = {
        inherit components;
        unwrapped = raven-unwrapped;
      };
    };

  raven = lib.makeOverridable makeRaven { };
in
{
  inherit
    raven
    raven-unwrapped
    components
    ;
}
