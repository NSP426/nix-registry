{ config, ... }:
{
  sops.defaultSopsFile = ../secrets/zot.yaml;
  sops.secrets = {
    zot_admin_password = {
    owner = "zot";
    group = "zot";
    mode = "0400";
  };

  zot_ci_password = {
    owner = "zot";
    group = "zot";
    mode = "0400";
  };
  };

  services.zot = {
    enable = true;
    dataDir = "/var/lib/zot";

    # Nginx reverse proxy with Let's Encrypt
    # nginx = {
    #   enable = true;
    #   domain = "registry.drotek.com";
    #   forceSSL = true;
    #   acme = true;
    # };
    #
    # Declarative users — passwords from sops
    auth.users = {
      admin = {
        passwordFile = config.sops.secrets.zot_admin_password.path;
        admin = true;
      };
      ci-user = {
        passwordFile = config.sops.secrets.zot_ci_password.path;
      };
    };

    # Access control
    accessControl = {
      adminActions = [ "read" "create" "update" "delete" ];
      defaultPolicy = [ ];
      anonymousPolicy = [ ];
      repositories."drotek/**" = {
        policies = [
          {
            users = [ "ci-user" ];
            actions = [ "read" "create" "update" "delete" ];
          }
        ];
        defaultPolicy = [ ];
        anonymousPolicy = [ "read" ];
      };
    };

    # Retention — keep things tidy
    retention = {
      dryRun = false;
      delay = "24h";
      policies = [
        {
          repositories = [ "drotek/**" ];
          deleteReferrers = true;
          deleteUntagged = true;
          keepTags = [
            { patterns = [ "latest" ]; }
            { pushedWithin = "168h"; }
            { mostRecentlyPushedCount = 10; }
            { patterns = [ "v.*" ]; pulledWithin = "720h"; }
          ];
        }
      ];
      defaultPolicy = {
        deleteReferrers = false;
        deleteUntagged = true;
        keepTags = [
          { patterns = [ ".*" ]; }
        ];
      };
    };

    # Monitoring — local Prometheus and Grafana
    metrics.enable = true;
    enableLocalScraping = true;
    grafanaDashboard = true;
  };
}
