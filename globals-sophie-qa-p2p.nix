pkgs: {

  deploymentName = "sophie-qa-p2p";

  environmentName = "sophie_qa";

  relaysNew = "relays.${pkgs.globals.domain}";
  nbInstancesPerRelay = 1;

  withExplorer = false;

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "dev-deployer";
        dns = "dev-deployer";
      };
    };
  };
}
