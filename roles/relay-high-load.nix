pkgs:
with pkgs; with lib;
{name, ...}: {

  imports = [
    bcc-ops.roles.relay
  ];

  # Add host and container auto metrics and alarming
  services.custom-metrics.enableNetdata = true;
}
