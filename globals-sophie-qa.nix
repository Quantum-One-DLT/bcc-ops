pkgs: {

  deploymentName = "sophie-qa";
  environmentName = "sophie_qa";

  relaysNew = pkgs.globals.environmentConfig.relaysNew;

  withFaucet = true;
  withExplorer = true;
  explorerBackendsInContainers = true;
  withBccDBExtended = true;
  withSmash = true;
  withSubmitApi = true;
  faucetHostname = "faucet";
  minCpuPerInstance = 1;
  minMemoryPerInstance = 4;

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "dev-deployer";
        dns = "dev-deployer";
      };
    };
  };
}
