pkgs:
with pkgs.lib;
let
  benchmarkingParamsFile = ./benchmarking-cluster-params.json;
  benchmarkingParams =
    if __pathExists benchmarkingParamsFile
    then let r = __fromJSON (__readFile benchmarkingParamsFile);
         in if __hasAttr "meta" r
            then if __hasAttr "default_profile" r.meta then r
                 else abort "${benchmarkingParamsFile} must define 'meta.default_profile':  please run 'bench reinit' to update it"
            else abort "${benchmarkingParamsFile} must define the 'meta' section:  please run 'bench reinit' to update it"
    else abort "Benchmarking requires ${toString benchmarkingParamsFile} to exist.  Please, refer to documentation.";
  benchmarkingTopologyFile =
    ./topologies + "/bench-${benchmarkingParams.meta.topology}-${toString (__length benchmarkingParams.meta.node_names)}.nix";
  benchmarkingTopology =
    if __pathExists benchmarkingTopologyFile
    then __trace "Using topology:  ${benchmarkingTopologyFile}"
      (rewriteTopologyForProfile
        (import benchmarkingTopologyFile)
        benchmarkingProfile)
    else abort "Benchmarking topology file implied by configured node count ${toString (__length benchmarkingParams.meta.node_names)} does not exist: ${benchmarkingTopologyFile}";
  AurumGenesisFile  = ./keys/aurum-genesis.json;
  SophieGenesisFile = ./keys/genesis.json;
  SophieGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/GENHASH);
  ColeGenesisFile = ./keys/cole/genesis.json;
  ColeGenesisHash = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./keys/cole/GENHASH);
  envConfigBase = pkgs.tbcoNix.bccLib.environments.testnet;

  ### Benchmarking profiles are, currently, essentially name-tagger
  ### generator configs.
  benchmarkingProfileNameEnv = __getEnv("BENCHMARKING_PROFILE");
  ## WARNING: this logic must correspond to select_benchmarking_profile
  ##          in bench.sh.
  benchmarkingProfileName = if benchmarkingProfileNameEnv == ""
                            then benchmarkingParams.meta.default_profile
                            else benchmarkingProfileNameEnv;
  benchmarkingProfile =
    if __hasAttr benchmarkingProfileName benchmarkingParams
    then __trace "Using profile:  ${benchmarkingProfileName}"
         benchmarkingParams."${benchmarkingProfileName}"
    else abort "${benchmarkingParamsFile} does not define benchmarking profile '${benchmarkingProfileName}'.";

  rewriteTopologyForProfile =
    topo: prof:
    let fixupPools = core: (core //
          { pools = if __hasAttr "pools" core && core.pools != null
                    then (if core.pools == 1 then 1 else prof.genesis.dense_pool_density)
                    else 0; });
        pooledCores = map fixupPools topo.coreNodes;
    in (topo // {
      coreNodes = map withEventlog pooledCores;
    });
  withEventlog = def: recursiveUpdate {
    services.bcc-node.eventlog = mkForce true;
    services.bcc-node.package = mkForce pkgs.bcc-node-eventlogged;
  } def;

  metadata = {
    inherit benchmarkingProfileName benchmarkingProfile benchmarkingTopology;
  };

  benchmarkingLogConfig = name: {
    defaultScribes = [
      [ "StdoutSK" "stdout" ]
      [ "FileSK"   "logs/${name}.json" ]
    ];
    setupScribes = [
      {
        scKind     = "StdoutSK";
        scName     = "stdout";
        scFormat   = "ScJson"; }
      {
        scKind     = "FileSK";
        scName     = "logs/${name}.json";
        scFormat   = "ScJson";
        scRotation = {
          rpLogLimitBytes = 300000000;
          rpMaxAgeHours   = 24;
          rpKeepFilesNum  = 20;
        }; }
    ];
    options = {
      mapBackends = {
        "bcc.node.resources" = [ "KatipBK" ];
        "bcc.node.metrics"   = [ "EKGViewBK" ];
      };
    };
  };

in (rec {
  inherit benchmarkingProfile;

  networkName = "Benchmarking, size ${toString (__length benchmarkingTopology.coreNodes)}";

  withBccDBExtended = false;
  withExplorer = false;
  withMonitoring = false;
  explorerBackends = {};
  explorerActiveBackends = [];

  environmentName = "bench-${benchmarkingParams.meta.topology}-${benchmarkingProfileName}";

  sourcesJsonOverride = ./nix/sources.bench.json;

  environmentConfig = rec {
    relays = "relays.${pkgs.globals.domain}";
    edgePort = pkgs.globals.bccNodePort;
    private = true;
    networkConfig = (removeAttrs envConfigBase.networkConfig ["AurumGenesisHash"]) // {
      Protocol = "Bcc";
      inherit  AurumGenesisFile;
      inherit SophieGenesisFile SophieGenesisHash;
      inherit   ColeGenesisFile   ColeGenesisHash;
    };
    nodeConfig = (removeAttrs envConfigBase.nodeConfig ["AurumGenesisHash"]) // {
      Protocol = "Bcc";
      inherit  AurumGenesisFile;
      inherit SophieGenesisFile SophieGenesisHash;
      inherit   ColeGenesisFile   ColeGenesisHash;
    } // {
      sophie =
        { TestSophieHardForkAtEpoch = 0;
        };
      evie =
        { TestSophieHardForkAtEpoch = 0;
          TestAllegraHardForkAtEpoch = 0;
        };
      jen =
        { TestSophieHardForkAtEpoch = 0;
          TestAllegraHardForkAtEpoch = 0;
          TestJenHardForkAtEpoch    = 0;
        };
    }.${pkgs.globals.environmentConfig.generatorConfig.era};
    txSubmitConfig = {
      inherit (networkConfig) RequiresNetworkMagic;
      inherit AurumGenesisFile SophieGenesisFile ColeGenesisFile;
    } // pkgs.tbcoNix.bccLib.defaultExplorerLogConfig;

    ## This is overlaid atop the defaults in the tx-generator service,
    ## as specified in the 'bcc-node' repository.
    generatorConfig = benchmarkingProfile.generator;
  };

  topology = {
    relayNodes = map (recursiveUpdate {
      ## XXX: assumes we have `explorer` as our only relay.
      imports = [
        pkgs.bcc-ops.roles.tx-generator
        # ({ config, ...}: {
        # })
      ];
      documentation = {
        man.enable = false;
        doc.enable = false;
      };
      networking.firewall.allowPing = mkForce true;
      services.bcc-node.package = mkForce pkgs.bcc-node-eventlogged;
      systemd.services.dump-registered-relays-topology.enable = mkForce false;
    }) (benchmarkingTopology.relayNodes or []);
    coreNodes = map (recursiveUpdate {
      stakePool = true;

      documentation = {
        man.enable = false;
        doc.enable = false;
      };
      networking.firewall.allowPing = mkForce true;
      services.bcc-node.nodeConfig =
        recursiveUpdate
          (removeAttrs pkgs.globals.environmentConfig.nodeConfig ["AurumGenesisHash"])
          (recursiveUpdate
            (benchmarkingLogConfig "node")
            ({
               inherit SophieGenesisHash ColeGenesisHash;
               TracingVerbosity = "NormalVerbosity";
               minSeverity = "Debug";
               TurnOnLogMetrics = true;

               TestEnableDevelopmentHardForkEras = true;
               TestEnableDevelopmentNetworkProtocols = true;

               TraceMempool               = true;
               TraceTxInbound             = true;
               TraceBlockFetchClient      = true;
               TraceBlockFetchServer      = true;
               TraceChainSyncHeaderServer = true;
               TraceChainSyncClient       = true;
               TraceTxSubmissionProtocol  = true;
               TraceTxSubmission2Protocol = true;
            } //
            (benchmarkingProfile.node.extra_config or {})));
    }) (benchmarkingTopology.coreNodes or []);
  };

  ec2 = with pkgs.tbco-ops-lib.physical.aws;
    {
      instances = {
        core-node = c5-2xlarge;
        relay-node = c5-2xlarge;
      };
      credentials = {
        accessKeyIds = {
          TBCO = "dev-deployer";
          dns = "dev-deployer";
        };
      };
    };
})
