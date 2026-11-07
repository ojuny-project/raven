{
  lib,
  pkgs,
}:

{
  raven-unwrapped,
  extraPkgs ? (_: [ ]),
  extraLibraries ? (_: [ ]),
  extraProfile ? "",
  extraEnv ? { },
  extraBwrapArgs ? [ ],
  privateTmp ? true,
  meta ? { },
  passthru ? { },
}:

let
  basePkgs =
    p:
    with p;
    [
      bash
      coreutils
      findutils
      gnugrep
      gnused
      which
      wayland
      libxkbcommon
      pixman
      libxcb
      libX11
      libXext
      libGL
      libGLU
      mesa
      vulkan-loader
      libpulseaudio
      freetype
      openssl
      libpng
      liberation_ttf_v2
    ];
in
pkgs.buildFHSEnv {
  pname = "raven";
  version = "unstable";

  inherit
    extraBwrapArgs
    privateTmp
    ;

  includeClosures = true;
  multiArch = false;

  targetPkgs =
    p:
    basePkgs p
    ++ [ raven-unwrapped ]
    ++ extraPkgs p
    ++ extraLibraries p;

  profile = ''
    export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/dri
    export __EGL_VENDOR_LIBRARY_DIRS=/run/opengl-driver/share/glvnd/egl_vendor.d
    export LIBVA_DRIVERS_PATH=/run/opengl-driver/lib/dri

    case ":$XDG_DATA_DIRS:" in
      *:/run/opengl-driver/share:*) ;;
      *) export XDG_DATA_DIRS="/run/opengl-driver/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}" ;;
    esac

    ${lib.toShellVars extraEnv}
    ${extraProfile}
  '';

  runScript = "${raven-unwrapped}/bin/raven";

  inherit meta passthru;
}
