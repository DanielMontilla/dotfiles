{ self, pkgs, ... }:

{
  boot.loader = {
    timeout = "30";
    grub = {
      default = "saved";
    };
  };
}
