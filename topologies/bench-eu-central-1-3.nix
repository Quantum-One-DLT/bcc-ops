{
  coreNodes = [
    {
      name = "node-0";
      nodeId = 0;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-1" "node-2"];
      stakePool = true;
    }
    {
      name = "node-1";
      nodeId = 1;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-2" "node-0"];
      stakePool = true;
    }
    {
      name = "node-2";
      nodeId = 2;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-0" "node-1"];
    }
  ];

  relayNodes = [];

  legacyCoreNodes = [];

  legacyRelayNodes = [];
}
