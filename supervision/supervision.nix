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
    listenAddress = "127.0.0.1";

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
    listenAddress = "127.0.0.1";

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
        protocol = "http";
        http_addr = "127.0.0.1";
        http_port = 3000;
      };

      security = {
        admin_user = "admin";
        secret_key = "$__file{/var/lib/grafana/secret_key}";
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

  systemd.services.grafana-secret = {
    description = "Generate Grafana secret key";

    wantedBy = [ "multi-user.target" ];
    before = [ "grafana.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };

    script = ''
      install -d -m 0750 -o grafana -g grafana /var/lib/grafana

      if [ ! -f /var/lib/grafana/secret_key ]; then
        ${pkgs.openssl}/bin/openssl rand -hex 32 \
          > /var/lib/grafana/secret_key

        chown grafana:grafana /var/lib/grafana/secret_key
        chmod 600 /var/lib/grafana/secret_key
      fi
    '';
  };

}
