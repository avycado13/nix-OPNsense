{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.opnsense.firewall;
in {
  options = {
    opnsense.firewall.enable = mkEnableOption "Enable firewall management";

    opnsense.firewall.rules = mkOption {
      type = types.listOf (types.submodule {
        options = {
          description = mkOption {
            type = types.str;
            default = "";
            description = "Description of the firewall rule.";
          };

          action = mkOption {
            type = types.enum [ "pass" "block" "reject" ];
            default = "pass";
            description = "Firewall rule action (pass, block, reject).";
          };

          source = mkOption {
            type = types.str;
            default = "any";
            description = "Source IP or network.";
          };

          destination = mkOption {
            type = types.str;
            default = "any";
            description = "Destination IP or network.";
          };

          port = mkOption {
            type = types.str;
            default = "any";
            description = "Destination port.";
          };

          protocol = mkOption {
            type = types.enum [ "tcp" "udp" "icmp" "any" ];
            default = "any";
            description = "Protocol used by the rule.";
          };
        };
      });
      default = [];
      description = "List of firewall rules.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.rules != [];
        message = "Firewall management is enabled but no rules are defined.";
      }
    ];
  };
}