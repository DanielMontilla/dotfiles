{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nerd-fonts.zed-mono
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontDir.enable = true;
}
