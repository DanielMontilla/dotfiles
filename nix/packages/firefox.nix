# https://mynixos.com/nixpkgs/options/programs.firefox
{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.firefox ];

  programs.firefox = {
    enable = true;
    languagePacks = [ "en-US" ];
  };
}