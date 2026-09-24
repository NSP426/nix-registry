{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.zot;

  zot = pkgs.stdenvNoCC.mkDerivation {
    pname = "zot";
    version = "2.1.21";

    src = ./zot-linux-amd64;

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.glibc
    ];

    installPhase = ''
      install -Dm755 $src $out/bin/zot
    '';
  };
in
{
  options.services.zot = {
    enable = lib.mkEnableOption "Zot OCI registry";

    config = lib.mkOption {
      type = lib.types.path;
      default = ./config.json;
      description = "Zot configuration file.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."zot/config.json".source = cfg.config;

    systemd.services.zot = {
      description = "Zot OCI Registry";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${zot}/bin/zot serve /etc/zot/config.json";

        Restart = "on-failure";

        DynamicUser = true;
        StateDirectory = "zot";
        WorkingDirectory = "/var/lib/zot";
      };
    };
  };
}
