# https://mynixos.com/nixpkgs/options/programs.neovim
{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.neovim ];

  programs.neovim = {
    enable = true;
  };
}