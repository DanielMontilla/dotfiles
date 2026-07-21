{ config, pkgs, inputs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  programs.mosh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];
}
