{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.opnsense.services;
in {
  options = {
    opnsense.services.enable = mkEnableOption "Enable service management";

    opnsense.services.unbound = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Unbound DNS service.";
    };

    opnsense.services.openvpn = mkOption {
      type = types.bool;
      default = false;
      description = "Enable OpenVPN service.";
    };

    opnsense.services.ids = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Intrusion Detection System (Suricata).";
    };
  };

  config = mkIf cfg.enable {};
}