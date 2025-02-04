{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.bitwarden ];
}