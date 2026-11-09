{
  description = "Waterfox browser (official binary release)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        waterfox = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.waterfox;
      };

      overlays.default = final: prev: {
        waterfox = final.callPackage ./package.nix { };
      };

      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.waterfox;
          hostFile = "org.kde.plasma.browser_integration.json";
          hostDir = "/run/current-system/sw/lib/mozilla/native-messaging-hosts";
        in {
          options.programs.waterfox = {
            enable = lib.mkEnableOption "Waterfox browser";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.waterfox;
              description = "The Waterfox package to install.";
            };

            plasmaIntegration = lib.mkEnableOption
              "KDE Plasma browser integration (native messaging host and per-user symlink)";
          };

          config = lib.mkIf cfg.enable (lib.mkMerge [
            {
              # makes `pkgs.waterfox` available too
              nixpkgs.overlays = [ self.overlays.default ];

              environment.systemPackages = [ cfg.package ];
            }

            (lib.mkIf cfg.plasmaIntegration {
              environment.systemPackages = [ pkgs.kdePackages.plasma-browser-integration ];

              # Creates ~/.mozilla/native-messaging-hosts/<manifest> for every user at login
              systemd.user.tmpfiles.rules = [
                "d %h/.mozilla/native-messaging-hosts 0755 - - -"
                "L+ %h/.mozilla/native-messaging-hosts/${hostFile} - - - - ${hostDir}/${hostFile}"
              ];
            })
          ]);
        };
    };
}
