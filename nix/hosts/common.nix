{ self, pkgs, ... }:

{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 30;
    grub = {
      enable = true;
      efiSupport = true;
      default = "saved";
      devices = [ "nodev" ];
      useOSProber = true;
    };
  };
}
