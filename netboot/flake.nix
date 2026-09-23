{
  description = "NixOS netboot module - proxy DHCP, TFTP and HTTP";

  outputs = { self, ... }: {
    nixosModules.netboot =
      {
        config,
        lib,
        pkgs,
        ...
      }:

      let
        cfg = config.services.netboot;

        tftpRoot = "${cfg.root}/tftp";
        httpRoot = "${cfg.root}/http";

        # iPXE images supplied by nixpkgs.
        ipxe = pkgs.ipxe;

      in
      {
        options.services.netboot = {
          enable = lib.mkEnableOption "PXE netboot services";

          interface = lib.mkOption {
            type = lib.types.str;
            default = "enp3s0";
            description = "Interface on which PXE clients are connected.";
          };

          subnet = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.0";
            description = "Network address used for proxy DHCP.";
          };

          root = lib.mkOption {
            type = lib.types.str;
            default = "/srv/netboot";
            description = "Root directory for TFTP and HTTP files.";
          };

          httpPort = lib.mkOption {
            type = lib.types.port;
            default = 8080;
            description = "HTTP port used for netboot files.";
          };
        };

        config = lib.mkIf cfg.enable {

          environment.systemPackages = [
            pkgs.dnsmasq
            pkgs.ipxe
            pkgs.curl
          ];

          # ------------------------------------------------------------
          # Netboot directories
          # ------------------------------------------------------------

          systemd.tmpfiles.rules = [
            "d ${cfg.root} 0755 root root -"
            "d ${tftpRoot} 0755 root root -"
            "d ${httpRoot} 0755 root root -"
          ];

          # ------------------------------------------------------------
          # Install iPXE binaries
          #
          # TFTP layout:
          #
          #   tftp/
          #   ├── undionly.kpxe       BIOS
          #   ├── ipxe.efi            x86_64 UEFI
          #   └── ipxe-arm64.efi     ARM64 UEFI
          #
          # ------------------------------------------------------------

          systemd.services.netboot-ipxe = {
            description = "Install iPXE PXE boot files";

            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;

              ExecStart = pkgs.writeShellScript "install-ipxe" ''
                set -eu

                mkdir -p ${tftpRoot}

                # Legacy BIOS
                install -Dm644 \
                  ${ipxe}/undionly.kpxe \
                  ${tftpRoot}/undionly.kpxe

                # x86_64 UEFI
                install -Dm644 \
                  ${ipxe}/ipxe.efi \
                  ${tftpRoot}/ipxe.efi

                # # ARM64 UEFI
                # install -Dm644 \
                #   ${ipxe}/ipxe-arm64.efi \
                #   ${tftpRoot}/ipxe-arm64.efi
              '';
            };
          };

          # ------------------------------------------------------------
          # dnsmasq
          # ------------------------------------------------------------
          services.dnsmasq = {
            enable = true;

            settings = {
              # Only listen on the PXE interface.
              interface = cfg.interface;
              bind-interfaces = true;

              # ------------------------------------------------------------
              # Proxy DHCP ONLY
              #
              # The real DHCP server on the network assigns:
              #   - IP address
              #   - subnet mask
              #   - gateway
              #   - DNS
              #
              # dnsmasq only answers PXE/DHCP boot requests.
              # ------------------------------------------------------------

              dhcp-range = [
                "${cfg.subnet},proxy"
              ];

              # Do NOT provide DNS.
              port = 0;

              # ------------------------------------------------------------
              # TFTP
              # ------------------------------------------------------------

              enable-tftp = true;
              tftp-root = tftpRoot;

              # ------------------------------------------------------------
              # PXE architecture detection
              # ------------------------------------------------------------

              dhcp-match = [
                # BIOS
                "set:bios,option:client-arch,0"

                # x86 UEFI
                "set:efi-x86,option:client-arch,7"
                "set:efi-x86,option:client-arch,9"

                # ARM64 UEFI
                "set:efi-arm64,option:client-arch,11"
              ];

              # ------------------------------------------------------------
              # PXE bootloader
              # ------------------------------------------------------------

              dhcp-boot = [
                "tag:bios,undionly.kpxe"
                "tag:efi-x86,ipxe.efi"
                "tag:efi-arm64,ipxe-arm64.efi"
              ];

              # Useful for troubleshooting PXE.
              log-dhcp = true;

              # Don't act as a DNS resolver/cache.
              no-resolv = true;
            };
          };

          # ------------------------------------------------------------
          # HTTP server
          # ------------------------------------------------------------

          systemd.services.netboot-http = {
            description = "Netboot HTTP server";

            wantedBy = [ "multi-user.target" ];

            after = [
              "network-online.target"
            ];

            wants = [
              "network-online.target"
            ];

            serviceConfig = {
              DynamicUser = true;
              Restart = "on-failure";

              ExecStart = ''
                ${pkgs.python3}/bin/python3 \
                  -m http.server \
                  ${toString cfg.httpPort} \
                  --directory ${httpRoot}
              '';
            };
          };

          # ------------------------------------------------------------
          # Firewall
          # ------------------------------------------------------------

          networking.firewall.allowedTCPPorts = [
            cfg.httpPort
          ];

          networking.firewall.allowedUDPPorts = [
            67 # DHCP
            69 # TFTP
          ];
        };
      };
  };
}
