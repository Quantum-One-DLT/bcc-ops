{
  coreNodes = [
    {
      name = "node-0";
      nodeId = 0;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-1" "node-2"];
    }
    {
      name = "node-1";
      nodeId = 1;
      org = "TBCO";
      region = "ap-southeast-2";
      producers = ["node-2" "node-0"];
      pools = 1;
    }
    {
      name = "node-2";
      nodeId = 2;
      org = "TBCO";
      region = "us-east-1";
      producers = ["node-0" "node-1"];
      pools = 10;
    }
  ];

  relayNodes = [
    {
      name = "explorer";
      nodeId = 3;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-0" "node-1" "node-2"];
    }
  ];
}
