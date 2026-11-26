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
          ravenLog = pkgs.writeShellApplication {
            name = "raven";
            runtimeInputs = [
              pkgs.coreutils
              ravenPackages.raven
            ];
            text = ''
              log="''${XDG_STATE_HOME:-''${HOME:-/tmp}/.local/state}/ojuny/raven/last-exit.log"
              mkdir -p "$(dirname "$log")"
              exec 3>"$log"
              status=0
              raven --exit-code-fd 3 "$@" || status=$?
              exec 3>&-
              guest="$(cat "$log" 2>/dev/null || true)"
              printf 'raven: host exit %s, guest exit %s\n' "$status" "''${guest:-unknown}" >&2
              exit "$status"
            '';
          };
        in
        {
          default = ravenLog;
          inherit (ravenPackages) raven raven-unwrapped;
          inherit ravenLog;
        }
      );

      devShells = eachSystem (
        pkgs:
        import ./nix/devshell.nix {
          inherit (pkgs) lib;
          inherit pkgs;
        }
      );

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
