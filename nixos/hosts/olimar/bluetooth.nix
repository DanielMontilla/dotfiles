{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # PipeWire already enabled in packages.nix; WirePlumber handles
  # the BlueZ audio endpoints (A2DP/HFP) automatically once BlueZ runs.

  environment.systemPackages = with pkgs; [
    bluetui
    bluez
  ];
}
