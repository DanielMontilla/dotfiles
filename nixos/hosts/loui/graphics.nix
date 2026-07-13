{ config, pkgs, ... }:

{
  # Mesa: provides Vulkan (radv / amdvlk) + OpenGL that niri's wgpu renderer
  # needs. Without this, even a loaded GPU kernel module leaves niri with no
  # renderer -> black screen.
  hardware.graphics.enable = true;

  # AMD Raphael integrated GPU (Ryzen iGPU) - very stable with niri.
  boot.kernelModules = [ "amdgpu" ];

  # NVIDIA RTX 5070 Ti (Blackwell) discrete GPU.
  # Blackwell requires the open kernel modules; use the latest driver branch
  # for 50-series support.
  hardware.nvidia = {
    enable = true;
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
