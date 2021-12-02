pkgs: with pkgs.tbcoNix.bccLib; with pkgs.globals; {

  # This should match the name of the topology file.
  deploymentName = "aurum-qa";

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
      environments.aurum-white.nodeConfig
      {
        SophieGenesisFile = ./keys/genesis.json;
        SophieGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/GENHASH);
        ColeGenesisFile = ./keys/cole/genesis.json;
        ColeGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/cole/GENHASH);
        TestSophieHardForkAtEpoch = 0;
        TestAllegraHardForkAtEpoch = 0;
        TestJenHardForkAtEpoch = 0;
        TestAurumHardForkAtEpoch = 0;
        MaxKnownMajorProtocolVersion = 5;
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
