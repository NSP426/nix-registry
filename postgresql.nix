{ config, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    #    package = pkgs.postgresql_16;

    settings = {
      listen_addresses = "localhost";
      unix_socket_directories = "/run/postgresql";
    };

    ensureUsers = [
      {
        name = "root";
        ensureClauses = {
          superuser = true;
          login = true;
          password = "tartufiotuc11";
        };
      }
    ];
  };

  services.pgadmin = {
    enable = true;
    port = 5050;

    initialEmail = "nicolas.sanspiche@drotek.com";
    initialPasswordFile = "/etc/pgadmin/password";
  };
}
