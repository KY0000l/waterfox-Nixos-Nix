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
    };
}
