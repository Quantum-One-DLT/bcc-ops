pkgs: with pkgs; with lib; with topology-lib;
let

  regions =  {
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

  nodes = with regions; map (composeAll [
    (withAutoRestartEvery 6)
    (withModule {
      services.bcc-node = {
        asserts = true;
        systemdSocketActivation = mkForce false;
      };
    })
  ]) (concatLists [
    (mkStakingPoolNodes "d" 1 "a" "P2P1" { org = "TBCO"; nodeId = 1; })
    (mkStakingPoolNodes "e" 2 "b" "P2P2" { org = "TBCO"; nodeId = 2; })
    (mkStakingPoolNodes "f" 3 "c" "P2P3" { org = "TBCO"; nodeId = 3; })
  ]);

  relayNodes = filter (n: !(n ? stakePool)) nodes;

  coreNodes = filter (n: n ? stakePool) nodes;

in {

  inherit coreNodes relayNodes regions;

  monitoring = {
    services.monitoring-services.publicGrafana = false;
    services.nginx.virtualHosts."monitoring.${globals.dnsZone}".locations."/p" = {
      root = ../static/pool-metadata;
    };
  };

}
