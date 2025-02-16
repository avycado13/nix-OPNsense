{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.opnsense.dhcp;
in {
  options = {
    opnsense.dhcp.enable = mkEnableOption "Enable DHCP server";

    opnsense.dhcp.subnets = mkOption {
      type = types.listOf (types.submodule {
        options = {
          interface = mkOption {
            type = types.str;
            description = "Interface for the DHCP subnet.";
          };

          range = mkOption {
            type = types.str;
            description = "DHCP range (e.g., 192.168.1.100-192.168.1.200).";
          };

          gateway = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Gateway for DHCP clients.";
          };

          dns = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of DNS servers for DHCP clients.";
          };
        };
      });
      default = [];
      description = "List of DHCP subnets.";
    };
  };

  config = mkIf cfg.enable {};
}