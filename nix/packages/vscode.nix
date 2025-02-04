{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.vscode ];
}