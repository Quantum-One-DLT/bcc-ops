{ pkgs, ... }@args:
with pkgs;
tbco-ops-lib.physical.aws.security-groups.allow-all-to-tcp-port
  "bcc" globals.bccNodePort args
