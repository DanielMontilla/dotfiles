# https://mynixos.com/nixpkgs/options/programs.git
{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.git ];

  programs.git = {
    enable = true;
    config = {
      init = {
        defaultBranch = "master";
      };
    };
  };
}