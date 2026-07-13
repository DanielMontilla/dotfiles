{ config, pkgs, ... }:

{
  boot.loader = {
    timeout = 15;
    efi.canTouchEfiVariables = true;
    grub.enable = false;

    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      editor = false;
      extraInstallCommands = ''
        echo 'default @saved' >> /boot/loader/loader.conf

        echo 'title Windows' > /boot/loader/entries/windows.conf
        echo 'efi /EFI/Microsoft/Boot/bootmgfw.efi' >> /boot/loader/entries/windows.conf
      '';
    };
  };
}
