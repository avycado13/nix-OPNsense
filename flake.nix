{
  description = "Nix-based configuration management for OPNsense";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; # Adjust as needed
      pkgs = import nixpkgs { inherit system; };
    in {
      nixosModules.opnsense = import ./modules/system.nix;
      packages.${system} = {
        opnsense-apply = pkgs.writeScriptBin "opnsense-apply" (builtins.readFile ./lib/apply-config.nix);
      };
    };
}