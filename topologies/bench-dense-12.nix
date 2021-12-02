{
  coreNodes = [
    {
      name = "node-0";
      nodeId = 0;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-1" "node-2" "node-3" "node-4" "node-5" "node-6" "node-7" "node-8" "node-9" "node-10" "node-11"];
    }
    {
      name = "node-1";
      nodeId = 1;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-0" "node-2" "node-3" "node-4" "node-5" "node-6" "node-7" "node-8" "node-9" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-2";
      nodeId = 2;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-0" "node-1" "node-3" "node-4" "node-5" "node-6" "node-7" "node-8" "node-9" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-3";
      nodeId = 3;
      org = "TBCO";
      region = "eu-central-1";
      producers = ["node-0" "node-1" "node-2" "node-4" "node-5" "node-6" "node-7" "node-8" "node-9" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-4";
      nodeId = 4;
      org = "TBCO";
      region = "ap-southeast-2";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-5" "node-6" "node-7" "node-8" "node-9" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-5";
      nodeId = 5;
      org = "TBCO";
      region = "ap-southeast-2";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4" "node-6" "node-7" "node-8" "node-9" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-6";
      nodeId = 6;
      org = "TBCO";
      region = "ap-southeast-2";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4" "node-5" "node-7" "node-8" "node-9" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-7";
      nodeId = 7;
      org = "TBCO";
      region = "ap-southeast-2";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4" "node-5" "node-6" "node-8" "node-9" "node-10" "node-11"];
      pools = 100;
    }

    {
      name = "node-8";
      nodeId = 8;
      org = "TBCO";
      region = "us-east-1";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4" "node-5" "node-6" "node-7" "node-9" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-9";
      nodeId = 9;
      org = "TBCO";
      region = "us-east-1";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4" "node-5" "node-6" "node-7" "node-8" "node-10" "node-11"];
      pools = 100;
    }
    {
      name = "node-10";
      nodeId = 10;
      org = "TBCO";
      region = "us-east-1";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4" "node-5" "node-6" "node-7" "node-8" "node-9" "node-11"];
      pools = 100;
    }
    {
      name = "node-11";
      nodeId = 11;
      org = "TBCO";
      region = "us-east-1";
      producers = ["node-0" "node-1" "node-2" "node-3" "node-4" "node-5" "node-6" "node-7" "node-8" "node-9" "node-10"];
      pools = 1;
    }
  ];

  relayNodes = [];
}
