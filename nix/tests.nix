{
  lib,
  pkgs,
}:

{
  default =
    (import ./package.nix {
      inherit lib pkgs;
      withTests = true;
    }).raven-unwrapped;

  package =
    (import ./package.nix {
      inherit lib pkgs;
    }).raven-unwrapped;
}
