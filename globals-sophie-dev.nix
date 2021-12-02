pkgs: with pkgs; with tbcoNix.bccLib; rec {

  withMonitoring = false;
  withExplorer = false;

  environmentName = "sophie-dev";

  environmentConfig = rec {
    relays = "relays.${pkgs.globals.domain}";
    genesisFile = ./keys/genesis.json;
    genesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/GENHASH);
    nodeConfig = lib.recursiveUpdate environments.sophie_qa.nodeConfig {
      SophieGenesisFile = genesisFile;
      SophieGenesisHash = genesisHash;
      Protocol = "TOptimum";
      TraceBlockFetchProtocol = true;
    };
    explorerConfig = mkExplorerConfig environmentName nodeConfig;
  };

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "dev-deployer";
        dns = "dev-deployer";
      };
    };
  };
}
