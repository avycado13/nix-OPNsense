{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.opnsense.networking;
in {
  options = {
    opnsense.networking.enable = mkEnableOption "Enable networking configuration";

    opnsense.networking.interfaces = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Interface name (e.g., igb0, em1).";
          };

          ipv4 = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Static IPv4 address (CIDR notation).";
          };

          ipv6 = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Static IPv6 address (CIDR notation).";
          };

          dhcp = mkOption {
            type = types.bool;
            default = false;
            description = "Enable DHCP on this interface.";
          };
        };
      });
      default = [];
      description = "List of network interfaces.";
    };
  };

  config = mkIf cfg.enable {};
}