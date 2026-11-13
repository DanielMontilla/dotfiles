{ config, pkgs, inputs, ... }:

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
    # nixpkgs-25.11 ships 580.119.02, whose open module loses the Vulkan device
    # on Blackwell (NVRM: VM: invalid mmap -> VK_ERROR_DEVICE_LOST). Zed then
    # segfaults recreating its GPU context. Pull the driver from unstable,
    # built against the running 6.12 kernel so the module still matches.
    #
    # Do NOT use `latest` here: in unstable that tracks `bleeding_edge`
    # (610.57.04). `production` is the stable branch (595.99.02); fall back to
    # generation 48 (580) if it misbehaves.
    package = (inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackagesFor pkgs.linux).nvidiaPackages.production;
  };

  # The driver comes from nixpkgs-unstable, whose nvidia-x11 package no longer
  # bundles the EGL external-platform libraries (the stable 580 package did).
  # Without them glvnd has no GBM platform for the NVIDIA driver: niri's
  # EGLDisplay::new(gbm) fails with "EGL is not initialized", it falls back to
  # the AMD iGPU (no outputs attached), and the session never lights up.
  # Unstable's NixOS module adds these to /run/opengl-driver; stable's does not
  # (it expects them inside the driver package), so add them by hand.
  hardware.graphics.extraPackages =
    let unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in [
      unstable.egl-gbm
      unstable.egl-wayland
      unstable.egl-wayland2
      unstable.egl-x11
    ];

  # Force niri/wgpu onto the Vulkan backend (needed for the NVIDIA path).
  environment.sessionVariables = {
    WGPU_BACKEND = "vulkan";
  };
}
