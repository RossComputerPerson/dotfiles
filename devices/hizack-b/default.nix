{ config, lib, pkgs, ... }:
let
  box64' = pkgs.box64.overrideAttrs (f: p: {
    cmakeFlags = p.cmakeFlags ++ [
      "-DM1=ON"
    ];
  });
in
{
  imports = [
    ../../system/linux/desktop.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.binfmt = {
    emulatedSystems = [
      "x86_64-linux"
      "i686-linux"
      "i386-linux"
    ];
    registrations = {
      i686-linux.interpreter = lib.mkForce (lib.getExe box64');
      x86_64-linux.interpreter = lib.mkForce (lib.getExe box64');
    };
  };

  boot.kernelPatches = [{
    name = "waydroid";
    patch = null;
    extraConfig = ''
      ANDROID_BINDER_IPC y
      ANDROID_BINDERFS y
      ANDROID_BINDER_DEVICES binder,hwbinder,vndbinder
      ASHMEM y
      ANDROID_BINDERFS y
      ANDROID_BINDER_IPC y
    '';
  }];

  environment.systemPackages = with pkgs; [
    openscad
    mpv
    vlc
    box64'
  ];

  programs.firefox.enable = true;

  hardware.bluetooth.enable = true;
  networking = {
    hostName = "hizack-b";
    wireless = {
      enable = false;
      iwd.enable = true;
    };
    networkmanager = {
      wifi.backend = "iwd";
      plugins = lib.mkForce (with pkgs; [
        networkmanager-fortisslvpn
        networkmanager-iodine
        networkmanager-l2tp
        networkmanager-openvpn
        networkmanager-vpnc
        networkmanager-sstp
      ]);
    };
  };

  hardware.asahi = {
    extractPeripheralFirmware = true;
    peripheralFirmwareDirectory = ./firmware;
    useExperimentalGPUDriver = true;
    setupAsahiSound = true;
    experimentalGPUInstallMode = "overlay";
  };

  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=0
  '';

  fileSystems."/" = {
    device = "/dev/nvme0n1p5";
    fsType = "ext4";
  };

  home-manager.users.ross.wayland.windowManager.hyprland.package = pkgs.hyprland-legacy-renderer;
  home-manager.users.ross.xdg.configFile."kanshi/config".source = ./config/kanshi/config;
}
