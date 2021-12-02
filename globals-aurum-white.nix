pkgs: with pkgs.tbcoNix.bccLib; with pkgs.globals; {

  # This should match the name of the topology file.
  deploymentName = "aurum-white";

  withFaucet = true;
  withSmash = true;
  explorerBackends = {
    a = explorer11;
  };
  explorerBackendsInContainers = true;

  environmentConfigLocal = rec {
    relaysNew = "relays.${domain}";
    nodeConfig =
      pkgs.lib.recursiveUpdate
      environments.aurum-blue.nodeConfig
      {
        SophieGenesisFile = ./keys/genesis.json;
        SophieGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/GENHASH);
        ColeGenesisFile = ./keys/cole/genesis.json;
        ColeGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/cole/GENHASH);
        AurumGenesisFile = ./keys/genesis.aurum.json;
        AurumGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/AURUMGENHASH);
        TestSophieHardForkAtEpoch = 1;
        TestAllegraHardForkAtEpoch = 2;
        TestJenHardForkAtEpoch = 3;
        MaxKnownMajorProtocolVersion = 4;
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
