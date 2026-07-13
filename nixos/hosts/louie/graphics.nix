{ config, pkgs, ... }:

{
  # Mesa: provides the Vulkan loader / GLVND that niri's wgpu renderer needs.
  hardware.graphics.enable = true;

  # NVIDIA's driver is unfree; must be allowed to build (louie was missing this).
  nixpkgs.config.allowUnfree = true;

  # NVIDIA RTX 5070 Ti (Blackwell) is the only GPU with a display attached.
  # The nvidia module is activated by selecting it as the X video driver
  # (there is no hardware.nvidia.enable option). Blackwell requires the open
  # kernel modules, and modesetting is required for Wayland compositors (niri).
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # Force niri/wgpu onto the Vulkan backend (needed for the NVIDIA path).
  environment.sessionVariables = {
    WGPU_BACKEND = "vulkan";
  };
}
