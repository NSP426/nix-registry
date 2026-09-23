{
  config,
  pkgs,
  lib,
  ...
}:

{
  # =========================
  # Prometheus
  # =========================
  services.prometheus = {
    enable = true;

    # Prometheus écoute sur localhost:9090
    port = 9090;

    # Conservation des métriques
    retentionTime = "30d";

    scrapeConfigs = [
      {
        job_name = "node";

        static_configs = [
          {
            targets = [ "localhost:9100" ];
          }
        ];
      }
    ];
  };

  # =========================
  # Node Exporter
  # =========================
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;

    enabledCollectors = [
      "cpu"
      "meminfo"
      "diskstats"
      "filesystem"
      "loadavg"
      "netdev"
      "systemd"
    ];
  };

  # =========================
  # Grafana
  # =========================
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };

      security = {
        admin_user = "admin";
      };
    };

    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];
    };
  };

  # =========================
  # PostgreSQL
  # =========================
  services.postgresql = {
    enable = true;

    package = pkgs.postgresql_16;

    ensureDatabases = [
      "metrics"
    ];

    ensureUsers = [
      {
        name = "metrics";
        ensureDBOwnership = true;
      }
    ];
  };

  # =========================
  # Firewall
  # =========================
  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
  ];
}
