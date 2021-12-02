pkgs:
with pkgs;
let
  boolOption = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
in {
  imports = [
    tbco-ops-lib.modules.common
  ];

  config = {
    services.monitoring-exporters.logging = false;
  };

  options = {
    node = {
      coreIndex = lib.mkOption {
        type = lib.types.int;
      };
      nodeId = lib.mkOption {
        type = lib.types.int;
      };
      roles = {
        isColeProxy = boolOption;
        isBccCore = boolOption;
        isBccDensePool = boolOption;
        isBccLegacyCore = boolOption;
        isBccLegacyRelay = boolOption;
        isBccRelay = boolOption;
        isExplorer = boolOption;
        isFaucet = boolOption;
        isMonitor = boolOption;
        isMetadata = boolOption;
        isPublicSsh = boolOption;
        isSmash = boolOption;
      };
    };
  };
}
