pkgs: with pkgs.tbcoNix.bccLib; rec {

  withMonitoring = false;
  withExplorer = false;

  # This should match the name of the topology file.
  environmentName = "example";

  environmentConfig = rec {
    relays = "relays.${pkgs.globals.domain}";
    genesisFile = ./keys/genesis.json;
    genesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/GENHASH);
    nodeConfig =
      pkgs.lib.recursiveUpdate
      environments.sophie_qa.nodeConfig
      {
        SophieGenesisFile = genesisFile;
        SophieGenesisHash = genesisHash;
        Protocol = "TOptimum";
        TraceForge = true;
        TraceTxInbound = true;
      };
    explorerConfig = mkExplorerConfig environmentName nodeConfig;
  };

  topology = import (./topologies + "/${environmentName}.nix") pkgs;

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "dev-deployer";
        dns = "dev-deployer";
      };
    };
  };
}
