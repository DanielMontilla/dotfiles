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
        sed -i '/^default /d' /boot/loader/loader.conf
        echo 'default @saved' >> /boot/loader/loader.conf

        cat > /boot/loader/entries/windows.conf <<EOF
title Windows
efi /EFI/Microsoft/Boot/bootmgfw.efi
EOF
      '';
    };
  };
}
