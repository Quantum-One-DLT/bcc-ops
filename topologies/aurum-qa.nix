pkgs: with pkgs; with lib; with topology-lib;
let

  regions = {
    a = { name = "eu-central-1";   # Europe (Frankfurt);
    };
    b = { name = "us-east-2";      # US East (Ohio)
    };
    c = { name = "ap-southeast-1"; # Asia Pacific (Singapore)
    };
    d = { name = "eu-west-2";      # Europe (London)
    };
    e = { name = "us-west-1";      # US West (N. California)
    };
    f = { name = "ap-northeast-1"; # Asia Pacific (Tokyo)
    };
  };

  bftNodes = [
    (mkBftCoreNode "a" 1 { org = "TBCO"; nodeId = 1; })
  ];

  nodes = with regions; map (composeAll [
    (withAutoRestartEvery 6)
  ]) (concatLists [
    (mkStakingPoolNodes "a" 1 "d" "IOQA1" { org = "TBCO"; nodeId = 2; })
    (mkStakingPoolNodes "b" 2 "e" "IOQA2" { org = "TBCO"; nodeId = 3; })
    (mkStakingPoolNodes "c" 3 "f" "IOQA3" { org = "TBCO"; nodeId = 4; })
  ] ++ bftNodes);

  relayNodes = regionalConnectGroupWith bftNodes (fullyConnectNodes
    (filter (n: !(n ? stakePool)) nodes));

  coreNodes = filter (n: n ? stakePool) nodes;

in {

  inherit coreNodes relayNodes regions;


  explorer = {
    containers = mapAttrs (b: _: {
      config = {
        services.bcc-graphql = {
          allowListPath = mkForce null;
          allowIntrospection = true;
        };
        services.bcc-node = {
          package = mkForce bcc-node;
        };
      };
    }) globals.explorerBackends;
  };

  smash = {
    services.bcc-node = {
      package = mkForce bcc-node;
    };
  };

  "${globals.faucetHostname}" = {
    services.bcc-faucet = {
      anonymousAccess = false;
      faucetLogLevel = "DEBUG";
      secondsBetweenRequestsAnonymous = 86400;
      secondsBetweenRequestsApiKeyAuth = 86400;
      entropicsToGiveAnonymous = 1000000000;
      entropicsToGiveApiKeyAuth = 10000000000;
      useColeWallet = false;
    };
    services.bcc-node = {
      package = mkForce bcc-node;
    };
  };

  monitoring = {
    services.monitoring-services.publicGrafana = true;
    services.nginx.virtualHosts."monitoring.${globals.domain}".locations."/p" = {
      root = ../static/pool-metadata;
    };
  };

}
