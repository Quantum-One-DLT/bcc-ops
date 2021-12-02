pkgs: {

  deploymentName = "testnet";

  dnsZone = "${pkgs.globals.domain}";

  domain = "bcc-testnet.tbcodev.io";

  withSubmitApi = true;
  withFaucet = true;
  withSmash = true;
  withMetadata = true;
  withHighLoadRelays = true;

  faucetHostname = "faucet";

  initialPythonExplorerDBSyncDone = true;

  environmentName = "testnet";

  topology = import ./topologies/testnet.nix pkgs;

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "default";
        dns = "default";
      };
    };
    instances.metadata = pkgs.tbco-ops-lib.physical.aws.t3a-xlarge;
  };

  relayUpdateArgs = "-m 50 -s -e devops@tbco.io";
  # Trigger relay topology refresh 12 hours before next epoch
  relayUpdateHoursBeforeNextEpoch = 12;
  dbSyncSnapshotPeriod = "15d";

  dbSyncSnapshotArgs = "-e devops@tbco.io";

  alertChainDensityLow = "50";

  dbSyncSnapshotS3Bucket = "updates-bcc-testnet";
}
