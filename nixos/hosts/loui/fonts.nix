{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontDir.enable = true;
}
