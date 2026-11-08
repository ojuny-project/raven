{
  self,
}:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.raven;

  defaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.raven;

  graphicsLibraries =
    if pkgs.stdenv.hostPlatform.is64bit then
      [ config.hardware.graphics.package ] ++ config.hardware.graphics.extraPackages
    else
      [ config.hardware.graphics.package32 ] ++ config.hardware.graphics.extraPackages32;

  ravenPackage = cfg.package.override (previous: {
    extraLibraries =
      p:
      (if previous ? extraLibraries then previous.extraLibraries p else [ ])
      ++ cfg.extraLibraries
      ++ graphicsLibraries;

    extraPkgs =
      p:
      (if previous ? extraPkgs then previous.extraPkgs p else [ ])
      ++ cfg.extraPackages
      ++ cfg.fontPackages;
  });
in
{
  options.programs.raven = {
    enable = lib.mkEnableOption "Raven Windows application runtime";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "self.packages.${pkgs.stdenv.hostPlatform.system}.raven";
      description = "The Raven package to use.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages added to the Raven FHS environment.";
    };

    extraLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional libraries added to the Raven FHS environment.";
    };

    fontPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = builtins.filter lib.types.package.check config.fonts.packages;
      defaultText = lib.literalExpression "builtins.filter lib.types.package.check config.fonts.packages";
      description = "Font packages made available under /usr/share/fonts inside the Raven FHS environment.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = lib.mkDefault true;
    environment.systemPackages = [ ravenPackage ];
  };

  meta.maintainers = [ ];
}
