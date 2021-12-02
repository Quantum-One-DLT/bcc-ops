{ bcc-ops ? { outPath = ./.; rev = "abcdef"; } }:
let
  sources = import ./nix/sources.nix;
  pkgs = import ./nix {};

in pkgs.lib.fix (self: {
  inherit (pkgs)
    kes-rotation
    nginxExplorer
    node-update
    prometheus-varnish-exporter
    varnish
    varnish-modules;

  forceNewEval = pkgs.writeText "forceNewEval" bcc-ops.rev;

  required = pkgs.releaseTools.aggregate {
    name = "required";
    constituents = with self; [
      forceNewEval
      kes-rotation
      nginxExplorer
      node-update
      prometheus-varnish-exporter
      varnish
      varnish-modules
    ];
  };
})
