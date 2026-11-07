{
  lib,
  pkgs,
}:

let
  mingw64 = pkgs.pkgsCross.mingwW64.stdenv.cc;
  mingw32 = pkgs.pkgsCross.mingw32.stdenv.cc;

  tools =
    with pkgs;
    [
      cmake
      ninja
      python3
      pkg-config
      clang
      lld
      bison
      patch
      zstd
      findutils
      openssl
      wayland
      libffi
      wayland-protocols
      libxkbcommon
      pixman
      libxcb
      libX11
      libXext
      libGL
      libGLU
      vulkan-loader
      vulkan-headers
      freetype
      libpng
      libpulseaudio
      mesa
      wine64Packages.minimal
      labwc
      grim
      wlrctl
      wtype
      wl-clipboard
      xvfb
      openbox
      xdotool
      xclip
      python3Packages.pillow
      mingw64
      mingw32
    ];

  fhs = pkgs.buildFHSEnv {
    pname = "raven-dev";
    version = "unstable";
    targetPkgs = _: tools;
    runScript = "bash";
  };
in
{
  default = pkgs.mkShell {
    packages = tools;
    shellHook = ''
      echo "Raven development shell"
      echo "CMake, Python 3, both MinGW toolchains, and the host desktop libraries are available."
    '';
  };

  fhs = fhs.env;
}
