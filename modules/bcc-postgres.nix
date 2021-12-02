pkgs: { config, ... }:
with pkgs;

let
  inherit (lib) mkForce mkIf mkEnableOption mkOption types;
  cfg = config.services.bcc-postgres;
in {
  options = {
    services.bcc-postgres = {
      enable = mkEnableOption "Bcc Postgres";
      postgresqlSocketPath = mkOption {
        description = "The postgresql socket path to use, typically `/run/postgresql`.";
        type = types.str;
        default = "/run/postgresql";
      };
      postgresqlDataDir = mkOption {
        description = "The directory for postgresql data.  If null, this parameter is not configured.";
        type = types.nullOr types.str;
        default = null;
      };
      withHighCapacityPostgres = mkOption {
        description = "Configure postgresql to use additional resources to support high RAM and connection requirements.";
        type = types.bool;
        default = globals.withHighCapacityExplorer;
      };
    };
  };
  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = postgresql_12;
      dataDir = mkIf (cfg.postgresqlDataDir != null) cfg.postgresqlDataDir;
      enableTCPIP = false;
    } // (lib.optionalAttrs (!(lib.hasPrefix "20.03"  lib.version)) {
      settings = if cfg.withHighCapacityPostgres then {
        # Optimized for:
        # DB Version: 12
        # OS Type: linux
        # DB Type: web
        # Total Memory (RAM): 24 GB (75% the RAM of high capacity explorer)
        # CPUs num: 8 (high capacity explorer vCPUs)
        # Connections num: 2000
        # Data Storage: ssd
        # Suggested optimization for
        # other configurations can be
        # found at:
        # https://pgtune.leopard.in.ua/
        max_connections = 2000;
        shared_buffers = "6GB";
        effective_cache_size = "18GB";
        maintenance_work_mem = "1536MB";
        checkpoint_completion_target = 0.7;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        work_mem = "5242kB";
        min_wal_size = "1GB";
        max_wal_size = "4GB";
        max_worker_processes = 8;
        max_parallel_workers_per_gather = 4;
        max_parallel_workers = 8;
        max_parallel_maintenance_workers = 4;
        shared_preload_libraries = "pg_stat_statements";
        "pg_stat_statements.track" = "all";
      } else {
        # DB Version: 12
        # OS Type: linux
        # DB Type: web
        # Total Memory (RAM): 8 GB (half the RAM of regular explorer)
        # CPUs num: 4 (explorer vCPUs)
        # Connections num: 200
        # Data Storage: ssd
        max_connections = 200;
        shared_buffers = "2GB";
        effective_cache_size = "6GB";
        maintenance_work_mem = "512MB";
        checkpoint_completion_target = 0.7;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        work_mem = "5242kB";
        min_wal_size = "1GB";
        max_wal_size = "4GB";
        max_worker_processes = 4;
        max_parallel_workers_per_gather = 2;
        max_parallel_workers = 4;
        max_parallel_maintenance_workers = 2;
        shared_preload_libraries = "pg_stat_statements";
        "pg_stat_statements.track" = "all";
      };
    }) // (lib.optionalAttrs (lib.hasPrefix "20.03"  lib.version) {
      extraConfig = if cfg.withHighCapacityPostgres then ''
        # Optimized for:
        # DB Version: 12
        # OS Type: linux
        # DB Type: web
        # Total Memory (RAM): 24 GB (75% the RAM of high capacity explorer)
        # CPUs num: 8 (high capacity explorer vCPUs)
        # Connections num: 2000
        # Data Storage: ssd
        # Suggested optimization for
        # other configurations can be
        # found at:
        # https://pgtune.leopard.in.ua/
        max_connections = 2000
        shared_buffers = 6GB
        effective_cache_size = 18GB
        maintenance_work_mem = 1536MB
        checkpoint_completion_target = 0.7
        wal_buffers = 16MB
        default_statistics_target = 100
        random_page_cost = 1.1
        effective_io_concurrency = 200
        work_mem = 5242kB
        min_wal_size = 1GB
        max_wal_size = 4GB
        max_worker_processes = 8
        max_parallel_workers_per_gather = 4
        max_parallel_workers = 8
        max_parallel_maintenance_workers = 4
        shared_preload_libraries = 'pg_stat_statements'
        pg_stat_statements.track = all
      '' else ''
        # DB Version: 12
        # OS Type: linux
        # DB Type: web
        # Total Memory (RAM): 8 GB (half the RAM of regular explorer)
        # CPUs num: 4 (explorer vCPUs)
        # Connections num: 200
        # Data Storage: ssd
        max_connections = 200
        shared_buffers = 2GB
        effective_cache_size = 6GB
        maintenance_work_mem = 512MB
        checkpoint_completion_target = 0.7
        wal_buffers = 16MB
        default_statistics_target = 100
        random_page_cost = 1.1
        effective_io_concurrency = 200
        work_mem = 5242kB
        min_wal_size = 1GB
        max_wal_size = 4GB
        max_worker_processes = 4
        max_parallel_workers_per_gather = 2
        max_parallel_workers = 4
        max_parallel_maintenance_workers = 2
        shared_preload_libraries = 'pg_stat_statements'
        pg_stat_statements.track = all
      '';
    });
  };
}
