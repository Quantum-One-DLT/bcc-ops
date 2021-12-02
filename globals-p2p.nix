pkgs: with pkgs.tbcoNix.bccLib; with pkgs.globals; {

  # This should match the name of the topology file.
  deploymentName = "p2p";

  withFaucet = true;

  explorerBackends = {
    a = explorer11;
  };
  explorerBackendsInContainers = true;

  overlay = self: super: {
    sourcePaths = super.sourcePaths // {
      # Use p2p branch everywhere:
      bcc-node = super.sourcePaths.bcc-node-service;
    };
  };

  ec2 = {
    credentials = {
      accessKeyIds = {
        TBCO = "default";
        dns = "dev";
      };
    };
  };
}
