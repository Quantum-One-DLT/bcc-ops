self: super: with self; {
  bccNodePkgs = import (sourcePaths.bcc-node + "/nix") { gitrev = self.sourcePaths.bcc-node.rev; };
  bccNodeServicePkgs = import (sourcePaths.bcc-node-service + "/nix") { gitrev = self.sourcePaths.bcc-node-service.rev; };

  inherit (import (sourcePaths.bcc-db-sync + "/nix") {}) bccDbSyncHaskellPackages;

  inherit (bccNodePkgs.bccNodeHaskellPackages.bcc-cli.components.exes) bcc-cli;
  inherit (bccNodePkgs.bccNodeHaskellPackages.bcc-submit-api.components.exes) bcc-submit-api;
  inherit (bccNodePkgs.bccNodeHaskellPackages.bcc-node.components.exes) bcc-node;
  inherit ((if (sourcePaths ? shardagnostic-network)
    then (import (sourcePaths.shardagnostic-network + "/nix") {}).arkNetworkHaskellPackages
    else bccNodePkgs.bccNodeHaskellPackages).network-mux.components.exes) bcc-ping;
  inherit (bccNodePkgs.bccNodeHaskellPackages.locli.components.exes) locli;
  inherit (bccNodePkgs.bccNodeHaskellPackages.tx-generator.components.exes) tx-generator;

  bcc-node-eventlogged = bccNodePkgs.bccNodeEventlogHaskellPackages.bcc-node.components.exes.bcc-node;

  bcc-node-services-def = (sourcePaths.bcc-node-service or sourcePaths.bcc-node) + "/nix/nixos";
}
