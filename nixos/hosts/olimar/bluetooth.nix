{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
        Enable = "Source,Sink,Media,Socket";
        MultiProfile = "multiple";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Keep high-quality A2DP as default; stop WirePlumber from
  # auto-dropping to mono HFP whenever an app opens a mic.
  services.pipewire.wireplumber.extraConfig."10-bluez" = {
    "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.enable-hw-volume" = true;
      "bluez5.roles" = [ "a2dp_sink" "a2dp_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
    };
  };

  services.pipewire.wireplumber.extraConfig."11-bluetooth-policy" = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = false;
    };
  };

  # PipeWire already enabled in packages.nix; WirePlumber handles
  # the BlueZ audio endpoints (A2DP/HFP) automatically once BlueZ runs.

  environment.systemPackages = with pkgs; [
    bluetui
    bluez
    pavucontrol
    pwvucontrol
  ];
}
