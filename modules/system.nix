{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.opnsense;
in {
  options = {
    opnsense.enable = mkEnableOption "Enable OPNsense configuration management";

    opnsense.hostname = mkOption {
      type = types.str;
      default = "opnsense.local";
      description = "Hostname for the OPNsense system.";
    };

    opnsense.firewall.enable = mkEnableOption "Enable firewall management";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.hostname != "";
        message = "Hostname cannot be empty.";
      }
    ];
  };
}