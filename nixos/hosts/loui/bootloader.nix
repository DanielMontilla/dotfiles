{ config, pkgs, ... }:

{
  boot.loader = {
    timeout = 15;
    efi.canTouchEfiVariables = true;
    grub.enable = false;

    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      extraConfig = ''
        default @saved
      '';
    };
  };
}
