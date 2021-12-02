{ system ? builtins.currentSystem
, crossSystem ? null
, config ? {}
}:
let
  defaultSourcePaths = import ./sources.nix { inherit pkgs; };

  # use our own nixpkgs if it exists in our sources,
  # otherwise use tbcoNix default nixpkgs.
  defaultNixpkgs = if (defaultSourcePaths ? nixpkgs)
    then defaultSourcePaths.nixpkgs
    else (import defaultSourcePaths.tbco-nix {}).nixpkgs;

  inherit (import defaultNixpkgs { overlays = [globalsOverlay]; }) globals;

  sourcesOverride = let sourcesFile = globals.sourcesJsonOverride; in
    if (builtins.pathExists sourcesFile)
    then import ./sources.nix { inherit pkgs sourcesFile; }
    else {};

  sourcePaths = defaultSourcePaths // sourcesOverride;

  tbcoNix = import sourcePaths.tbco-nix {};

  nixpkgs = if (sourcesOverride ? nixpkgs) then sourcesOverride.nixpkgs else defaultNixpkgs;

  # overlays from ops-lib (include ops-lib sourcePaths):
  ops-lib-overlays = (import sourcePaths.ops-lib { withRustOverlays = false; }).overlays;
  nginx-overlay = self: super: let
    acceptLanguage = {
      src = self.fetchFromGitHub {
        name = "nginx_accept_language_module";
        owner = "giom";
        repo = "nginx_accept_language_module";
        rev = "2f69842f83dac77f7d98b41a2b31b13b87aeaba7";
        sha256 = "1hjysrl15kh5233w7apq298cc2bp4q1z5mvaqcka9pdl90m0vhbw";
      };
    };
  in rec {
    luajit = super.luajit.withPackages (ps: with ps; [cjson]);
    nginxExplorer = super.nginxStable.override (oldAttrs: {
      modules = oldAttrs.modules ++ [
        acceptLanguage
        self.nginxModules.develkit
        self.nginxModules.lua
      ];
    });
    nginxSmash = super.nginxStable.override (oldAttrs: {
      modules = oldAttrs.modules ++ [
        self.nginxModules.develkit
        self.nginxModules.lua
      ];
    });
    nginxMetadataServer = nginxSmash;
  };

  varnish-overlay = self: super: rec {
    inherit (super.callPackages ../pkgs/varnish {})
      varnish60
      varnish61
      varnish62
      varnish63
      varnish64
      varnish65;

    inherit (super.callPackages ../pkgs/varnish/packages.nix { inherit
      varnish60
      varnish61
      varnish62
      varnish63
      varnish64
      varnish65;
    })
      varnish60Packages
      varnish61Packages
      varnish62Packages
      varnish63Packages
      varnish64Packages
      varnish65Packages;

    varnishPackages = varnish65Packages;
    varnish = varnishPackages.varnish;
    varnish-modules = varnishPackages.modules;

    prometheus-varnish-exporter = super.callPackage ../pkgs/prometheus-varnish-exporter {};
  };

  # our own overlays:
  local-overlays = [
    (import ./bcc.nix)
    (import ./packages.nix)
  ];

  globalsOverlay =
    if builtins.pathExists ../globals.nix
    then (pkgs: _: with pkgs.lib; let
      globalsDefault = import ../globals-defaults.nix pkgs;
      globalsSpecific = import ../globals.nix pkgs;
    in {
      globals = globalsDefault // (recursiveUpdate {
        inherit (globalsDefault) ec2 libvirtd environmentVariables;
      } globalsSpecific);
    })
    else builtins.trace "globals.nix missing, please add symlink" (pkgs: _: {
      globals = import ../globals-defaults.nix pkgs;
    });

  # merge upstream sources with our own:
  upstream-overlay = self: super: {
      inherit tbcoNix;
    bcc-ops = {
      inherit overlays;
      modules = self.importWithPkgs ../modules;
      roles = self.importWithPkgs ../roles;
    };
    sourcePaths = (super.sourcePaths or {}) // sourcePaths;
  };

  overlays =
    ops-lib-overlays ++
    local-overlays ++
    [
      upstream-overlay
      nginx-overlay
      varnish-overlay
      globalsOverlay
      globals.overlay
    ];

    pkgs = import nixpkgs {
      inherit system crossSystem config overlays;
    };
in
  pkgs
