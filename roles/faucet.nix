pkgs: { name, config, nodes, resources, ... }:
with pkgs;
let
  faucetPkgs = (import (sourcePaths.bcc-faucet + "/nix") {});
  walletPackages = import sourcePaths.bcc-wallet { gitrev = sourcePaths.bcc-wallet.rev; };
  inherit (walletPackages) bcc-wallet bcc-node;
  inherit (pkgs.lib) mkIf;
in {

  imports = [
    bcc-ops.modules.base-service

    # Bcc faucet needs to pair a compatible version of wallet with node
    # The following service import will do this:
    (sourcePaths.bcc-faucet + "/nix/nixos/bcc-faucet-service.nix")
  ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  environment.systemPackages = with pkgs; [
    sqlite-interactive
  ];

  services.bcc-faucet = {
    enable = true;
    bccEnv = globals.environmentName;
    bccEnvAttrs = globals.environmentConfig;
    walletPackage = bcc-wallet;
  };

  services.bcc-node = {
    package = bcc-node;
    allProducers = if (globals.topology.relayNodes != [])
        then [ globals.relaysNew ]
        else (map (n: n.name) globals.topology.coreNodes);
    topology = lib.mkForce null;
    totalMaxHeapSizeMbytes = 0.6 * config.node.memory * 1024;
  };

  deployment.keys = {
    "faucet.mnemonic" = {
      keyFile = ../static + "/faucet.mnemonic";
      destDir = "/var/lib/keys/";
      user = "bcc-node";
      permissions = "0400";
    };

    "faucet.passphrase" = {
      keyFile = ../static + "/faucet.passphrase";
      destDir = "/var/lib/keys/";
      user = "bcc-node";
      permissions = "0400";
    };

    "faucet.recaptcha" = {
      keyFile = ../static + "/faucet.recaptcha";
      destDir = "/var/lib/keys/";
      user = "bcc-node";
      permissions = "0400";
    };

    "faucet.apikey" = {
      keyFile = ../static + "/faucet.apikey";
      destDir = "/var/lib/keys/";
      user = "bcc-node";
      permissions = "0400";
    };
  };
  users.users.bcc-node.extraGroups = [ "keys" ];

  security.acme = mkIf (config.deployment.targetEnv != "libvirtd") {
    email = "devops@blockchain-company.io";
    acceptTerms = true; # https://letsencrypt.org/repository/
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    serverTokens = false;
    mapHashBucketSize = 128;

    commonHttpConfig = ''
      log_format x-fwd '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

      access_log syslog:server=unix:/dev/log x-fwd;

      limit_req_zone $binary_remote_addr zone=faucetPerIP:100m rate=1r/s;
      limit_req_status 429;
      server_names_hash_bucket_size 128;

      map $http_origin $origin_allowed {
        default 0;
        https://testnets.bcc.org 1;
        https://developers.bcc.org 1;
        https://staging-testnets-bcc.netlify.app 1;
        http://localhost:8000 1;
      }

      map $origin_allowed $origin {
        default "";
        1 $http_origin;
      }
    '';

    virtualHosts = {
      "${name}.${globals.domain}" = {
        forceSSL = config.deployment.targetEnv != "libvirtd";
        enableACME = config.deployment.targetEnv != "libvirtd";

        locations."/" = {
          extraConfig = let
            headers = ''
              add_header 'Vary' 'Origin' always;
              add_header 'Access-Control-Allow-Origin' $origin always;
              add_header 'Access-Control-Allow-Methods' 'POST, OPTIONS' always;
              add_header 'Access-Control-Allow-Headers' 'User-Agent,X-Requested-With,Content-Type' always;
            '';
          in ''
            limit_req zone=faucetPerIP;

            if ($request_method = OPTIONS) {
              ${headers}
              add_header 'Access-Control-Max-Age' 1728000;
              add_header 'Content-Type' 'text/plain; charset=utf-8';
              add_header 'Content-Length' 0;
              return 204;
              break;
            }

            if ($request_method = POST) {
              ${headers}
            }

            proxy_pass http://127.0.0.1:${
              toString config.services.bcc-faucet.faucetListenPort
            };
            proxy_set_header Host $host:$server_port;
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
      };
    };
  };
}
