{
  coreNodes = [
    {
      name = "node-0";
      nodeId = 0;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-1" "node-2" "node-3" "node-4" "node-5"];
      pools = 1;
    }
    {
      name = "node-1";
      nodeId = 1;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-0" "node-2" "node-3" "node-4" "node-5"];
      pools = 1;
    }
    {
      name = "node-2";
      nodeId = 2;
      org = "TBCO";
      region = "ap-southeast-2";
      producers = ["node-0" "node-1" "node-3" "node-4" "node-5"];
    }
    {
      name = "node-3";
      nodeId = 3;
      org = "TBCO";
      region = "ap-southeast-2";
      producers = ["node-0" "node-1" "node-2" "node-4" "node-5"];
      pools = 1;
    }
    {
      name = "node-4";
      nodeId = 4;
      org = "TBCO";
      region = "us-east-1";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-5"];
      pools = 1;
    }
    {
      name = "node-5";
      nodeId = 5;
      org = "TBCO";
      region = "us-east-1";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4"];
    }
  ];

  relayNodes = [];
}
