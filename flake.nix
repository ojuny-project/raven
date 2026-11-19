{
  description = "Windows application runtime for Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = eachSystem (
        pkgs:
        let
          ravenPackages = import ./nix/package.nix {
            inherit (pkgs) lib;
            inherit pkgs;
          };
        in
        {
          default = ravenPackages.raven;
          inherit (ravenPackages) raven raven-unwrapped;
        }
      );

      devShells = eachSystem (pkgs: import ./nix/devshell.nix { inherit (pkgs) lib; inherit pkgs; });

      checks = eachSystem (
        pkgs:
        let
          tests = import ./nix/tests.nix {
            inherit (pkgs) lib;
            inherit pkgs;
          };
          ravenContract = pkgs.runCommand "check-raven-package-contract" { } ''
            while IFS= read -r name; do
              test -e ${tests.package}/libexec/raven/"$name"
            done < ${tests.package}/libexec/raven/runtime-contract.txt
            touch $out
          '';
        in
        {
          default = pkgs.runCommand "check-default" { } ''
            echo ${tests.default} >/dev/null
            echo ${ravenContract} >/dev/null
            touch $out
          '';
          raven-package-contract = ravenContract;
          inherit (tests) package;
        }
      );

      nixosModules.default = import ./nix/nixos.nix { inherit self; };

      overlays.default = final: _: {
        raven =
          (import ./nix/package.nix {
            inherit (final) lib;
            pkgs = final;
          }).raven;
        raven-unwrapped =
          (import ./nix/package.nix {
            inherit (final) lib;
            pkgs = final;
          }).raven-unwrapped;
      };

      formatter = eachSystem (pkgs: pkgs.nixfmt);
    };
}
