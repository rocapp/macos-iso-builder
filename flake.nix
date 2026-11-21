{
  description = "Build bootable macOS installer ISOs/DMGs with mkmaciso";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkMkmaciso = pkgs:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "mkmaciso";
          version = "0.1.0";

          src = self;

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            install -Dm755 mkmaciso "$out/bin/mkmaciso"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Build bootable macOS installer ISO/DMG images from Apple servers";
            homepage = "https://github.com/LongQT-sea/macos-iso-builder";
            license = licenses.gpl3Only;
            mainProgram = "mkmaciso";
            platforms = platforms.darwin;
          };
        };
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          mkmaciso = mkMkmaciso pkgs;

          default = self.packages.${system}.mkmaciso;
        });

      apps = forAllSystems (system: {
        mkmaciso = {
          type = "app";
          program = "${self.packages.${system}.mkmaciso}/bin/mkmaciso";
        };
        default = self.apps.${system}.mkmaciso;
      });

      overlays.default = final: prev: {
        mkmaciso = mkMkmaciso final;
      };

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          mkmaciso-bash-syntax = pkgs.runCommand "mkmaciso-bash-syntax" {
            nativeBuildInputs = [ pkgs.bash ];
          } ''
            bash -n ${self}/mkmaciso
            touch $out
          '';

          mkmaciso-shellcheck = pkgs.runCommand "mkmaciso-shellcheck" {
            nativeBuildInputs = [ pkgs.shellcheck ];
          } ''
            shellcheck --shell=bash --severity=warning ${self}/mkmaciso
            touch $out
          '';
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bashInteractive
              shellcheck
              actionlint
            ];
          };
        });

      formatter = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in pkgs.nixpkgs-fmt);
    };
}
