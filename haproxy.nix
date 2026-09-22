{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.haproxy = {
    enable = true;

    config = ''
            global
                log stdout format raw local0

      # generated 2026-09-22, TLSRef Guideline v6.0, HAProxy 3.0, OpenSSL 4.0.1, intermediate config, HSTS, gitrev=d96f668
      # https://configurator.tlsref.org/#server=haproxy&version=3.0&config=intermediate&openssl=4.0.1&hsts&guideline=6.0
      global
          # intermediate configuration
          ssl-default-bind-curves X25519MLKEM768:X25519:prime256v1:secp384r1
          ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305
          ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-bind-options prefer-client-ciphers ssl-min-ver TLSv1.2 no-tls-tickets

          ssl-default-server-curves X25519MLKEM768:X25519:prime256v1:secp384r1
          ssl-default-server-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305
          ssl-default-server-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-server-options ssl-min-ver TLSv1.2 no-tls-tickets

            defaults
                mode http
                log global
                option httplog

                timeout connect 5s
                timeout client 30s
                timeout server 30s

            # HTTP :80
            # Pas de redirection vers HTTPS

#            frontend http
 #               bind :80
  #              default_backend podman_app

            # HTTPS :443
            # HTTP/2 + HTTP/1.1

            frontend https
                bind :443 ssl crt /var/lib/haproxy/certs/server.pem alpn h2,http/1.1
                bind :80
                redirect scheme https code 308 if !{ ssl_fc }
                default_backend podman_app

                # HSTS (63072000 seconds)
          http-response set-header Strict-Transport-Security "max-age=63072000; includeSubDomains"

            # Backend Podman
            backend podman_app
                server app 127.0.0.1:5000 check
    '';
  };
}
