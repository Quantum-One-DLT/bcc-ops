
pkgs: nodeId: {config, name, ...}:
with pkgs;
let

  signingKey = ../keys/cole/delegate-keys + ".${leftPad (nodeId - 1) 3}.key";
  delegationCertificate = ../keys/cole/delegation-cert + ".${leftPad (nodeId - 1) 3}.json";

  vrfKey = ../keys/node-keys/node-vrf + "${toString nodeId}.skey";
  kesKey = ../keys/node-keys/node-kes + "${toString nodeId}.skey";
  operationalCertificate = ../keys/node-keys/node + "${toString nodeId}.opcert";
  bulkCredentials = ../keys/node-keys/bulk + "${toString nodeId}.creds";

  keysConfig = rec {
    RealPBFT = {
      _file = ./core.nix;
      services.bcc-node = {
        signingKey = "/var/lib/keys/bcc-node-signing";
        delegationCertificate = "/var/lib/keys/bcc-node-delegation-cert";
      };
      systemd.services."bcc-node" = {
        after = [ "bcc-node-signing-key.service" "bcc-node-delegation-cert-key.service" ];
        wants = [ "bcc-node-signing-key.service" "bcc-node-delegation-cert-key.service" ];
      };
      deployment.keys = {
        "bcc-node-signing" = builtins.trace ("${name}: using " + (toString signingKey)) {
            keyFile = signingKey;
            user = "bcc-node";
            group = "bcc-node";
            destDir = "/var/lib/keys";
        };
        "bcc-node-delegation-cert" = builtins.trace ("${name}: using " + (toString delegationCertificate)) {
            keyFile = delegationCertificate;
            user = "bcc-node";
            group = "bcc-node";
            destDir = "/var/lib/keys";
        };
      };
    };
    TOptimum =
      {
        _file = ./core.nix;

        services.bcc-node =
          if config.node.roles.isBccDensePool
          then {
            extraArgs = [ "--bulk-credentials-file" "/var/lib/keys/bcc-node-bulk-credentials" ];
          }
          else {
            kesKey = "/var/lib/keys/bcc-node-kes-signing";
            vrfKey = "/var/lib/keys/bcc-node-vrf-signing";
            operationalCertificate = "/var/lib/keys/bcc-node-operational-cert";
          };

        systemd.services."bcc-node" =
          if config.node.roles.isBccDensePool
          then {
            after  = [ "bcc-node-bulk-credentials-key.service" ];
            wants  = [ "bcc-node-bulk-credentials-key.service" ];
            partOf = [ "bcc-node-bulk-credentials-key.service" ];
          }
          else {
            after = [ "bcc-node-vrf-signing-key.service" "bcc-node-kes-signing-key.service" "bcc-node-operational-cert-key.service" ];
            wants = [ "bcc-node-vrf-signing-key.service" "bcc-node-kes-signing-key.service" "bcc-node-operational-cert-key.service" ];
            partOf = [ "bcc-node-vrf-signing-key.service" "bcc-node-kes-signing-key.service" "bcc-node-operational-cert-key.service" ];
          };

        deployment.keys =
          if config.node.roles.isBccDensePool
          then {
            "bcc-node-bulk-credentials" = builtins.trace ("${name}: using " + (toString bulkCredentials)) {
              keyFile = bulkCredentials;
              user = "bcc-node";
              group = "bcc-node";
              destDir = "/var/lib/keys";
            };
          }
          else {
            "bcc-node-vrf-signing" = builtins.trace ("${name}: using " + (toString vrfKey)) {
              keyFile = vrfKey;
              user = "bcc-node";
              group = "bcc-node";
              destDir = "/var/lib/keys";
            };
            "bcc-node-kes-signing" = builtins.trace ("${name}: using " + (toString kesKey)) {
              keyFile = kesKey;
              user = "bcc-node";
              group = "bcc-node";
              destDir = "/var/lib/keys";
            };
            "bcc-node-operational-cert" = builtins.trace ("${name}: using " + (toString operationalCertificate)) {
              keyFile = operationalCertificate;
              user = "bcc-node";
              group = "bcc-node";
              destDir = "/var/lib/keys";
            };
          };
      };
    Bcc =
      if !(builtins.pathExists signingKey) then TOptimum
      else if !(builtins.pathExists vrfKey) then RealPBFT
      else lib.recursiveUpdate TOptimum RealPBFT;
  };

in {

  imports = [
    bcc-ops.modules.base-service
    keysConfig.${globals.environmentConfig.nodeConfig.Protocol}
  ];

  users.users.bcc-node.extraGroups = [ "keys" ];

  deployment.ec2.ebsInitialRootDiskSize = globals.systemDiskAllocationSize
    + globals.nodeDbDiskAllocationSize;

}
