pkgs: {

  deploymentName = "mainnet";

  dnsZone = "${pkgs.globals.domain}";

  domain = "bcc-mainnet.tbco.io";

  explorerHostName = "explorer.bcc.org";
  explorerForceSSL = true;
  explorerAliases = [ "explorer.mainnet.bcc.org" "explorer.${pkgs.globals.domain}" ];

  withBccDBExtended = true;
  withHighCapacityMonitoring = true;
  withHighCapacityExplorer = true;
  withHighLoadRelays = true;
  withSmash = true;

  withMetadata = true;
  metadataHostName = "tokens.bcc.org";

  initialPythonExplorerDBSyncDone = true;

  environmentName = "mainnet";

  topology = import ./topologies/mainnet.nix pkgs;

  maxRulesPerSg = {
    TBCO = 61;
    Emurgo = 36;
    CF = 36;
  };

  minMemoryPerInstance = 10;

  # 20GB per node instance
  nodeDbDiskAllocationSize = 20;

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "mainnet-tbco";
        Emurgo = "mainnet-emurgo";
        CF = "mainnet-cf";
        dns = "mainnet-tbco";
      };
    };
  };

  relayUpdateArgs = "-m 1500 --maxNodes 12 -s -e devops@tbco.io";
  # Trigger relay topology refresh 12 hours before next epoch
  relayUpdateHoursBeforeNextEpoch = 12;

  dbSyncSnapshotArgs = "-e devops@tbco.io";

  alertChainDensityLow = "85";

  dbSyncSnapshotS3Bucket = "update-bcc-mainnet.tbco.io";
}
