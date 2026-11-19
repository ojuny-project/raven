{
  lib,
  pkgs,
  withControls ? true,
  withInstaller ? true,
  withGraphics ? true,
  withSqlite ? true,
  withFonts ? true,
  withSkia ? true,
  withTests ? false,
}:

let
  src = lib.cleanSource ../.;

  components = import ./components.nix {
    inherit lib pkgs src;
    pkgsCross = pkgs.pkgsCross;
  };

  version = "0-unstable-2026-11-19";

  mingw64 = pkgs.pkgsCross.mingwW64.stdenv.cc;
  mingw32 = pkgs.pkgsCross.mingw32.stdenv.cc;

  cargoDeps = pkgs.rustPlatform.importCargoLock {
    lockFile = ../native/waits/Cargo.lock;
  };

  runtimeComponents = [
    "comctl32.dll"
    "raven-user32.dll"
    "raven-shell.dll"
    "raven-dwrite.dll"
    "raven-d2d1.dll"
    "raven-uianimation.dll"
    "ucrtbase.dll"
    "dcomp.dll"
    "coremessaging.dll"
    "raven-web.dll"
    "raven-wmi.dll"
    "raven-ieframe.dll"
    "raven-winmm.dll"
    "raven-msacm32.dll"
    "dsound.dll"
    "ucrtbase32.dll"
    "raven-rtl.dll"
    "raven-storage.dll"
    "raven-appx.dll"
    "mspatcha.dll"
    "vbscript.dll"
    "scrrun.dll"
    "wshom.ocx"
    "jscript.dll"
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
    "cscript.exe"
    "wscript.exe"
    "control.exe"
    "raven-picker.exe"
    "raven-host.exe"
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

  testFilter = "^(pe_contracts|module_set_contracts|native_(cpu_contracts|memory_contracts|parallel_memory_contracts|parallel_stop_contract|x86_contracts|shared_mapping_contract|provider_contract|launch_arguments_contract|ansi_code_page|hlsl_compiler|update_regions|keyboard_layouts|font_ownership|compatible_bitmap_contract|bitblt_contract|class_info_ownership|window_data_ownership|brush_ownership|exception_contract|object_contract|handle_channel_contract|firmware_memory|string_resource_contract|resource_contract|process_parameters|menu_ownership|extract_icons_contract|png_codec_contract|icon_dib_contract|icon_group_contract|blackonwhite_contract|cpu_contracts_threaded|memory_contracts_threaded|cpu_contracts_agent|memory_contracts_agent|cpu_contracts_agent_threaded|memory_contracts_agent_threaded|cpu_contracts_held|memory_contracts_held|cpu_contracts_held_threaded|memory_contracts_held_threaded|x86_contracts_threaded|x86_contracts_held|x86_contracts_held_threaded|x86_contracts_agent|provider_contract_threaded|provider_contract_held|agent_contract|agent_process))$";

  raven-unwrapped = pkgs.stdenv.mkDerivation {
    pname = "raven-unwrapped";
    inherit version src;

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.ninja
      pkgs.python3
      pkgs.pkg-config
      pkgs.wayland
      pkgs.wayland-scanner
      pkgs.libffi
      pkgs.wayland-protocols
      pkgs.clang
      pkgs.lld
      pkgs.openssl
      pkgs.cargo
      pkgs.rustc
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
      pkgs.mesa
      pkgs.vulkan-loader
      pkgs.vulkan-headers
      pkgs.freetype
      pkgs.openssl
      pkgs.zlib
      pkgs.libpulseaudio
    ];

    preConfigure = ''
      export CARGO_HOME=$TMPDIR/cargo
      export CARGO_NET_OFFLINE=true
      mkdir -p "$CARGO_HOME"
      cat > "$CARGO_HOME/config.toml" <<EOF
      [source.crates-io]
      replace-with = "vendored-sources"

      [source.vendored-sources]
      directory = "${cargoDeps}"
      EOF
      mkdir -p build/testdata/downloads
      cp -a ${components.fixtures}/downloads/. build/testdata/downloads/
      sed -i 's/-mno-stack-arg-probe/-mno-stack-arg-probe -fno-stack-clash-protection -fomit-frame-pointer -momit-leaf-frame-pointer -O0/g' native/CMakeLists.txt
      sed -i '/add_custom_target(vulkan_.*_fixture ALL DEPENDS/ s/ ALL DEPENDS.*/)/' native/CMakeLists.txt
      sed -i '/add_custom_target(cxx_exception_fixtures ALL DEPENDS/ s/ ALL DEPENDS.*/)/' native/CMakeLists.txt
      sed -i '/add_custom_target(gcc_exceptions_fixture ALL DEPENDS/ s/ ALL DEPENDS.*/)/' native/CMakeLists.txt
    '';

    postConfigure = ''
      grep -q -- '-DRAVEN_WAYLAND' compile_commands.json build/compile_commands.json 2>/dev/null
    '' + lib.optionalString withSkia ''
      grep -q -- '-DRAVEN_SKIA' compile_commands.json build/compile_commands.json 2>/dev/null
    '';

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
      "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
      "-DRAVEN_VK_XML=${pkgs.vulkan-headers}/share/vulkan/registry/vk.xml"
      "-DRAVEN_VULKAN_CORE_HEADER=${pkgs.vulkan-headers}/include/vulkan/vulkan_core.h"
      "-DPNG_LIBRARY_RELEASE=${components.libpng}/lib/libpng16.a"
      "-DPNG_LIBRARY_DEBUG=${components.libpng}/lib/libpng16.a"
      "-DPNG_PNG_INCLUDE_DIR=${components.libpng}/include"
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
      "-DRAVEN_DXVK_PE64_DIR=${components.dxvk64}"
      "-DRAVEN_DXVK_PE32_DIR=${components.dxvk32}"
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
      install -Dm755 "$runtime/raven-runtime" $out/libexec/raven/raven-runtime
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

      if [ -d "$runtime/WinMetadata" ]; then
        mkdir -p $out/libexec/raven/WinMetadata
        for metadata in "$runtime"/WinMetadata/*.winmd; do
          install -Dm644 "$metadata" $out/libexec/raven/WinMetadata/$(basename "$metadata")
        done
      fi

      ${lib.optionalString withGraphics ''
        for library in ${components.dxvk64}/*.dll ${components.vkd3d}/pe64/*.dll; do
          install -Dm755 "$library" $out/libexec/raven/$(basename "$library")
        done
      ''}

      mkdir -p $out/libexec/raven/roots
      for certificate in ${components.roots}/*.crt; do
        install -Dm644 "$certificate" $out/libexec/raven/roots/$(basename "$certificate")
      done

      ${lib.optionalString (withFonts || withSkia) ''
        mkdir -p $out/libexec/raven/fonts
        for font in ${components.fonts}/*; do
          install -Dm644 "$font" $out/libexec/raven/fonts/$(basename "$font")
        done
        ln -s ${components.fonts} $out/libexec/raven/fonts-source
      ''}

      install -Dm644 ${src}/LICENSE $out/libexec/raven/LICENSE
      install -Dm644 ${src}/LICENSES.md $out/libexec/raven/LICENSES.md
      install -Dm644 ${src}/LICENSES.json $out/libexec/raven/LICENSES.json
      mkdir -p $out/libexec/raven/LICENSES
      for license in ${src}/LICENSES/*; do
        install -Dm644 "$license" $out/libexec/raven/LICENSES/$(basename "$license")
      done

      ln -s ../libexec/raven/raven $out/bin/raven

      python3 ${src}/nix/check-runtime-contract.py --build "$PWD" --out $out --source ${src} \
        --manifest $out/libexec/raven/runtime-contract.txt

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
