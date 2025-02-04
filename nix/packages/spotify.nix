{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.spotify ];
}