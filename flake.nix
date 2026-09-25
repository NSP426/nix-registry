{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    netboot = {
      url = "path:./netboot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      netboot,
      #      nur-packages,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "nsp";

    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          ./hardware-configuration.nix
          sops-nix.nixosModules.sops
          ./haproxy.nix
          ./postgresql.nix
          ./supervision/supervision.nix
          ./zot/zot.nix
          {
            services.zot.enable = true;
          }

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
          }
          #
          # netboot.nixosModules.netboot
          # {
          #   services.netboot = {
          #     enable = true;
          #
          #     interface = "enp3s0";
          #
          #     # Existing DHCP server's network.
          #     subnet = "10.10.0.0";
          #
          #     root = "/srv/netboot";
          #
          #     httpPort = 8080;
          #   };
          # }
          #
          ./vaultwarden/vaultwarden.nix

          ({ config, pkgs, ... }: {

            services.vaultwarden-custom = {
              enable = true;

              domain = "https://vault.drotek.com";
              port = 8222;
            };

            ############################################################
            # SYSTEM
            ############################################################

            system.stateVersion = "26.05";

            # nixpkgs.config.allowUnfree = true;

            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];

            ############################################################
            # BOOT / KERNEL
            ############################################################

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            ############################################################
            # NETWORK
            ############################################################

            networking.hostName = "cachos";
            networking.firewall.enable = false;

            networking.firewall.allowedTCPPorts = [
              22
            ];

            networking.interfaces.enp1s0 = {
              useDHCP = true;
            };

            networking.interfaces.enp2s0 = {
              useDHCP = true;
            };

            networking.interfaces.enp3s0 = {
              useDHCP = true;
            };

            ############################################################
            # LOCALE / KEYBOARD
            ############################################################

            time.timeZone = "Europe/Paris";

            i18n.defaultLocale = "fr_FR.UTF-8";

            i18n.extraLocaleSettings = {
              LC_ADDRESS = "fr_FR.UTF-8";
              LC_IDENTIFICATION = "fr_FR.UTF-8";
              LC_MEASUREMENT = "fr_FR.UTF-8";
              LC_MONETARY = "fr_FR.UTF-8";
              LC_NAME = "fr_FR.UTF-8";
              LC_NUMERIC = "fr_FR.UTF-8";
              LC_PAPER = "fr_FR.UTF-8";
              LC_TELEPHONE = "fr_FR.UTF-8";
              LC_TIME = "fr_FR.UTF-8";
            };

            console.keyMap = "fr";

            services.xserver.xkb.layout = "fr";

            ############################################################
            # DESKTOP / WAYLAND / SWAY
            ############################################################

            programs.sway = {
              enable = true;
              wrapperFeatures.gtk = true;
            };

            # Wayland / XWayland
            programs.xwayland.enable = true;

            # Sway is provider
            xdg.portal = {
              enable = true;
              xdgOpenUsePortal = true;
            };

            environment.sessionVariables = {
              QT_QPA_PLATFORM = "wayland";
              CLUTTER_BACKEND = "wayland";
              SDL_VIDEODRIVER = "wayland";
              GDK_BACKEND = "wayland";
              _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=lcd";
            };

            ############################################################
            # DISPLAY MANAGER
            ############################################################

            services.greetd = {
              enable = true;

              settings = {
                default_session = {
                  command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
                  user = "greeter";
                };
              };
            };

            services.gvfs.enable = true;

            ############################################################
            # BLUETOOTH
            ############################################################

            #hardware.bluetooth.enable = true;
            #services.blueman.enable = true;

            ############################################################
            # PRINTING
            ############################################################

            #services.printing.enable = true;

            ############################################################
            # SSH
            ############################################################

            services.openssh.enable = true;

            ############################################################
            # TIME SYNCHRONISATION
            ############################################################

            #services.timesyncd.enable = true;

            #services.flatpak.enable = true;
            ############################################################
            # FAIL2BAN
            ############################################################

            services.fail2ban.enable = true;

            ############################################################
            # VIRTUALISATION - LIBVIRT / KVM
            ############################################################

            #virtualisation.libvirtd.enable = true;
            #programs.virt-manager.enable = true;
            #virtualisation.docker.enable = true;
            #virtualisation.virtualbox.host.enable = true;

            virtualisation.containers.enable = true;
            virtualisation = {
              podman = {
                enable = true;

                # Create a `docker` alias for podman, to use it as a drop-in replacement
                dockerCompat = true;

                # Required for containers under podman-compose to be able to talk to each other.
                defaultNetwork.settings.dns_enabled = true;
              };
            };

            ############################################################
            # USERS
            ############################################################

            users.users.${username} = {
              isNormalUser = true;

              extraGroups = [
                "wheel"
                "networkmanager"
                "audio"
                "video"
                "input"
                "sudo"
                "dialout"
              ];

              shell = pkgs.zsh;
            };

            programs.zsh.enable = true;

            ############################################################
            # PROGRAMMES / PAQUETS UTILISATEUR
            ############################################################

            environment.systemPackages = with pkgs; [

              # --------------------------------------------------------
              # TERMINAL / SHELL
              # --------------------------------------------------------

              bash
              bash-completion
              zsh
              zsh-completions

              nano
              neovim
              less
              mc
              bc
              file
              tree
              wget
              curl
              rsync
              lsof
              hdparm
              dmidecode
              net-tools
              psmisc
              multitail
              ack
              lm_sensors
              htop

              ##########################################################
              # DEVELOPMENT
              ##########################################################

              gnumake
              gettext
              git
              git-lfs

              ncurses
              openssl

              jq

              ##########################################################
              # NETWORK
              ##########################################################

              bind
              traceroute
              inetutils
              netcat
              nftables
              openssh
              bmon

              ##########################################################
              # FILESYSTEM / DISK
              ##########################################################

              dosfstools
              e2fsprogs
              pciutils
              usbutils

              ##########################################################
              # ARCHIVES / FILES
              ##########################################################

              unzip
              zip
              p7zip
              bzip2
              gzip
              xz
              zstd
              cpio
#              cdrtools

              ##########################################################
              # GTK / DESKTOP
              ##########################################################

#              gtk4
              wayland
              wayland-protocols
              libxkbcommon
              mesa
#              vulkan-loader

              ##########################################################
              # SECURITY / ADMIN
              ##########################################################

              fail2ban

              groff
              man
              man-pages

              # nix style format
              nixfmt

              # nix secret
              age
              sops

              podman-tui
              podman-compose

            ];

            ############################################################
            # FONTS
            ############################################################

            fonts.packages = with pkgs; [
              font-awesome
              powerline-fonts
            ];

            ############################################################
            # ZRAM
            ############################################################

            zramSwap.enable = true;

          })
        ];
      };

    };
}
