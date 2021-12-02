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
    (withModule {
      services.bcc-node = {
        asserts = true;
        systemdSocketActivation = mkForce false;
      };
    })
  ]) (concatLists [
    (mkStakingPoolNodes "a" 1 "d" "P2P1" { org = "TBCO"; nodeId = 2; })
    (mkStakingPoolNodes "b" 2 "e" "P2P2" { org = "TBCO"; nodeId = 3; })
    (mkStakingPoolNodes "c" 3 "f" "P2P3" { org = "TBCO"; nodeId = 4; })
    (mkStakingPoolNodes "d" 4 "a" "P2P4" { org = "TBCO"; nodeId = 5; })
    (mkStakingPoolNodes "e" 5 "b" "P2P5" { org = "TBCO"; nodeId = 6; })
    (mkStakingPoolNodes "f" 6 "c" "P2P6" { org = "TBCO"; nodeId = 7; })
    (mkStakingPoolNodes "a" 7 "d" "P2P7" { org = "TBCO"; nodeId = 8; })
    (mkStakingPoolNodes "b" 8 "e" "P2P8" { org = "TBCO"; nodeId = 9; })
    (mkStakingPoolNodes "c" 9 "f" "P2P9" { org = "TBCO"; nodeId = 10; })
    (mkStakingPoolNodes "d" 10 "a" "P2P10" { org = "TBCO"; nodeId = 11; })
    (mkStakingPoolNodes "e" 11 "b" "P2P11" { org = "TBCO"; nodeId = 12; })
    (mkStakingPoolNodes "f" 12 "c" "P2P12" { org = "TBCO"; nodeId = 13; })
    (mkStakingPoolNodes "a" 13 "d" "P2P13" { org = "TBCO"; nodeId = 14; })
    (mkStakingPoolNodes "b" 14 "e" "P2P14" { org = "TBCO"; nodeId = 15; })
    (mkStakingPoolNodes "c" 15 "f" "P2P15" { org = "TBCO"; nodeId = 16; })
    (mkStakingPoolNodes "d" 16 "a" "P2P16" { org = "TBCO"; nodeId = 17; })
    (mkStakingPoolNodes "e" 17 "b" "P2P17" { org = "TBCO"; nodeId = 18; })
    (mkStakingPoolNodes "f" 18 "c" "P2P18" { org = "TBCO"; nodeId = 19; })
    (mkStakingPoolNodes "a" 19 "d" "P2P19" { org = "TBCO"; nodeId = 20; })
    (mkStakingPoolNodes "b" 20 "e" "P2P20" { org = "TBCO"; nodeId = 21; })
  ] ++ bftNodes);

  relayNodes = regionalConnectGroupWith bftNodes
    (filter (n: !(n ? stakePool)) nodes);

  coreNodes = filter (n: n ? stakePool) nodes;

in {

  inherit coreNodes relayNodes regions;

  explorer = {
    services.bcc-node = {
      package = mkForce bcc-node;
      systemdSocketActivation = mkForce false;
    };
    containers = mapAttrs (b: _: {
      config = {
        services.bcc-graphql = {
          allowListPath = mkForce null;
          allowIntrospection = true;
        };
        services.bcc-node = {
          package = mkForce bcc-node;
          systemdSocketActivation = mkForce false;
        };
      };
    }) globals.explorerBackends;
  };

  smash = {
    services.bcc-node = {
      package = mkForce bcc-node;
      systemdSocketActivation = mkForce false;
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
      systemdSocketActivation = mkForce false;
    };
  };

  monitoring = {
    services.monitoring-services.publicGrafana = false;
    services.nginx.virtualHosts."monitoring.${globals.domain}".locations."/p" = {
      root = ../static/pool-metadata;
    };
  };

}
