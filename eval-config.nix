let
  nixOPNsenseVersion = builtins.fromJSON (builtins.readFile ./version.json);

  checkRelease = lib:
    # Avoid breaking configurations when the unstable Nixpkgs version
    # rolls over.
    #
    # TODO: Something more refined than this would be ideal, as this
    # still means you could be using unstable nix-darwin 25.05 with
    # Nixpkgs 26.05, which would be unfortunate.
    if nixOPNsenseVersion.isReleaseBranch then
      lib.trivial.release == nixOPNsenseVersion.release
    else
      lib.versionAtLeast lib.trivial.release nixOPNsenseVersion.release;
in

{ lib
, modules
, baseModules ? import ./modules/module-list.nix
, specialArgs ? { }
, check ? true
, enableNixpkgsReleaseCheck ? true
}@args:

assert enableNixpkgsReleaseCheck -> checkRelease lib || throw ''

  nixOPNsense now uses release branches that correspond to Nixpkgs releases.
  The nixOPNsense and Nixpkgs branches in use must match, but you are currently
  using nixOPNsense ${nixOPNsenseVersion.release} with Nixpkgs ${lib.trivial.release}.

  You should use either the `nixpkgs-unstable` or
  `nixpkgs-YY.MM-OPNsense` branches of Nixpkgs. These correspond to the
  `master` and `nix-OPNsense-YY.MM` branches of nixOPNsense, respectively. Check
  <https://status.nixos.org/> for the currently supported Nixpkgs releases.

  If you’re using flakes, make sure your inputs look like this:

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/NIXPKGS-BRANCH";
        nixOPNsense.url = "github:avycado13/nix-OPNsense/NIX-OPNsense-BRANCH";
        nixOPNsense.inputs.nixpkgs.follows = "nixpkgs";
        # …
      };

  If you’re using channels, you can check your current channels with:

      $ sudo nix-channel --list
      nixpkgs https://nixos.org/channels/NIXPKGS-BRANCH
      OPNsense https://github.com/avycado13/nix-opnsense/NIX-OPNsense-BRANCH.tar.gz
      …
      $ nix-channel --list
      …

  If `darwin` or `nixpkgs` are present in `nix-channel --list` (without
  `sudo`), you should delete them with `nix-channel --remove NAME`. These can
  contribute to version mismatch problems.

  You can then fix your channels like this:

      $ sudo nix-channel --add https://nixos.org/channels/NIXPKGS-BRANCH nixpkgs
      $ sudo nix-channel --add https://github.com/avycado13/nix-opnsense/archive/NIX-OPNsense-BRANCH.tar.gz OPNsense
      $ sudo nix-channel --update

  After that, activating your system again should work correctly. If it
  doesn’t, please open an issue at
  <https://github.com/avycado13/nix-opnsense/issues/new> and include as much
  information as possible.
'';

let
  argsModule = {
    _file = ./eval-config.nix;
    config = {
      _module.args = {
        inherit baseModules modules;
      };
    };
  };

  eval = lib.evalModules (builtins.removeAttrs args [ "lib" "enableNixpkgsReleaseCheck" ] // {
    class = "OPNsense";
    modules = modules ++ [ argsModule ] ++ baseModules;
    specialArgs = { modulesPath = builtins.toString ./modules; } // specialArgs;
  });
in

{
  inherit (eval._module.args) pkgs;
  inherit (eval) options config;
  inherit (eval) _module;

  system = eval.config.system.build.toplevel;
}