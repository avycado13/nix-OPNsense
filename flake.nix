{
  description = "Nix-based configuration management for OPNsense";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux"];
      system = "x86_64-linux"; # Adjust as needed
      pkgs = import nixpkgs { inherit system; };
    in flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        default = pkgs.callPackage ./packages/default.nix {};
      };

      nixosModules = {
        opnsense = import ./modules/system.nix;
      };

    });
}