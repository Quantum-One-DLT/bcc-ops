pkgs: { config, options, nodes, name, ... }:
with pkgs; with lib;
let
  cfg = config.services.bcc-node;
  nodePort = globals.bccNodePort;
  hostAddr = getListenIp nodes.${name};
  monitoringPort = globals.bccNodePrometheusExporterPort;
in
{
  imports = [
    bcc-ops.modules.common
    (sourcePaths.bcc-node + "/nix/nixos")
  ];

  networking.firewall = {
    allowedTCPPorts = [ nodePort monitoringPort ];

    # TODO: securing this depends on CSLA-27
    # NOTE: this implicitly blocks DHCPCD, which uses port 68
    allowedUDPPortRanges = [ { from = 1024; to = 65000; } ];
  };

  services.bcc-node = {
    enable = true;
    inherit bccNodePkgs;
    rtsArgs = [ "-N2" "-A10m" "-qg" "-qb" "-M3G"];
    environment = globals.environmentName;
    port = nodePort;
    environments = {
      "${globals.environmentName}" = globals.environmentConfig;
    };
    nodeConfig = globals.environmentConfig.nodeConfig // {
      hasPrometheus = [ hostAddr globals.bccNodePrometheusExporterPort ];
      # Use Journald output:
      defaultScribes = [
        [
          "JournalSK"
          "bcc"
        ]
      ];
    };
    topology = tbcoNix.bccLib.mkEdgeTopology {
      inherit (cfg) port;
      edgeHost = globals.relaysNew;
      edgeNodes = [];
    };
  };
}
