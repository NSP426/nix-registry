{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.vaultwarden-custom;
in
{

  options.services.vaultwarden-custom = {
    enable = lib.mkEnableOption "Vaultwarden";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "https://vault.drotek.com";
      description = "URL publique de Vaultwarden.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8222;
      description = "Port d'écoute de Vaultwarden.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;

      ensureDatabases = [
        "vaultwarden"
      ];

      ensureUsers = [
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];
    };

    services.vaultwarden = {
      enable = true;

      package = pkgs.vaultwarden-postgresql;

      config = {
        DOMAIN = cfg.domain;

        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = cfg.port;

        #DATABASE_URL = "postgresql://vaultwarden@localhost/vaultwarden";
        DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";

        SIGNUPS_ALLOWED = false;

        WEBSOCKET_ENABLED = true;
      };
    };

    # force bin because packe option of vaultwarden service failed
    systemd.services.vaultwarden.serviceConfig.ExecStart =
      lib.mkForce "${pkgs.vaultwarden-postgresql}/bin/vaultwarden";

    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];
  };
}
