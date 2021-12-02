pkgs: with pkgs.tbcoNix.bccLib; with pkgs.globals; {

  # This should match the name of the topology file.
  deploymentName = "aurum-blue";

  withFaucet = true;
  withSmash = true;

  environmentConfigLocal = rec {
    relaysNew = "relays.${domain}";
    genesisFile = ./keys/genesis.json;
    nodeConfig =
      pkgs.lib.recursiveUpdate
      environments.aurum-blue.nodeConfig
      {
        SophieGenesisFile = genesisFile;
        SophieGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/GENHASH);
        ColeGenesisFile = ./keys/cole/genesis.json;
        ColeGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/cole/GENHASH);
        AurumGenesisFile = ./keys/genesis.aurum.json;
        AurumGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/AURUMGENHASH);
        TestSophieHardForkAtEpoch = 1;
        TestAllegraHardForkAtEpoch = 2;
        TestJenHardForkAtEpoch = 3;
        TestAurumHardForkAtEpoch = 10000;
      };
    explorerConfig = mkExplorerConfig environmentName nodeConfig;
  };

  # Every 5 hours:
  relayUpdatePeriod = "0/5:00:00";

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "default";
        dns = "dev";
      };
    };
  };
}
