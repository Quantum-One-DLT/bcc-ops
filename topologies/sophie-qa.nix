pkgs: with pkgs; with lib; with topology-lib;
let

  regions = {
    a = { name = "eu-central-1";   /* Europe (Frankfurt)       */ };
    b = { name = "us-east-2";      /* US East (Ohio)           */ };
    c = { name = "ap-southeast-1"; /* Asia Pacific (Singapore) */ };
    d = { name = "eu-west-2";      /* Europe (London)          */ };
  };

  stakingPoolNodes = fullyConnectNodes [
    (mkStakingPool "a" 1 "BCCCOIN1" { nodeId = 1; })
    (mkStakingPool "b" 1 "BCCCOIN2" { nodeId = 2; })
    (mkStakingPool "c" 1 "BCCCOIN3" { nodeId = 3; })
  ];

  coreNodes = map (withAutoRestartEvery 6) stakingPoolNodes;

  relayNodes = map (composeAll [
    (withAutoRestartEvery 6)
    #(withProfiling "time" ["rel-a-1"])
  ]) (mkRelayTopology {
    inherit regions coreNodes;
    autoscaling = false;
    maxProducersPerNode = 20;
    maxInRegionPeers = 5;
  });

in {

  inherit coreNodes relayNodes regions;

  monitoring = {
    services.monitoring-services.publicGrafana = false;
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


  explorer = {
    containers = mapAttrs (b: _: {
      config = {
        services.nginx.virtualHosts.explorer.locations."/p" = lib.mkIf (__pathExists ../static/pool-metadata) {
          root = ../static/pool-metadata;
        };
        services.bcc-graphql = {
          allowListPath = mkForce null;
          allowIntrospection = true;
        };
        services.bcc-node = {
          package = mkForce bcc-node;
        };
        services.bcc-db-sync = lib.mkIf (b == "a") {
          #takeSnapshot = "once";
          #restoreSnapshot = "db-sync-snapshot-schema-10-block-1254641-x86_64.tgz";
        };
      };
    }) globals.explorerBackends;
  };
}
