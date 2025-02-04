{ config, pkgs, lib, ... }:
let
  i3-randr-setup = pkgs.writeTextFile {
    name = "i3-randr-setup";
    destination = "/bin/i3-randr-setup";
    executable = true;

    text = ''
      xrandr --output DP-1 --mode 1920x1080 --pos 1920x0
      xrandr --output DP-3 --mode 1920x1080 --pos 0x1080
      xrandr --output HDMI-0 --mode 1920x1080 --pos 4480x1080 --rotate right
      xrandr --output DP-4 --mode 2560x1440 --pos 1920x1080 --rotate normal
    '';
  };
in
{
  imports = [
    ../../system/linux/desktop.nix
  ];

  environment.systemPackages = [ i3-randr-setup ];

  # Bootloader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/";

  # Initrd
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" "amdgpu" ];

  # Kernel
  boot.kernelModules = [ "kvm-amd" "overlay" "nct6775" ];
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
  '';

  # Hardware
  hardware.bluetooth.enable = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  virtualisation.docker.enableNvidia = true;

  environment.etc."sysconfig/lm_sensors".text = ''
    HWMON_MODULES="nct6775"
  '';

  # Networking
  networking.hostName = "lavienrose";
  networking.hostId = "04052e62";
  networking.interfaces.enp34s0.useDHCP = true;

  # Graphics
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  # Services
  services.irqbalance.enable = true;
  services.ananicy.enable = true;

  services.zfs = {
    trim = {
      enable = true;
    };
    autoScrub = {
      enable = true;
      pools = [ "rpool" ];
    };
    autoSnapshot = {
      enable = true;
      frequent = 8;
      monthly = 1;
    };
  };

  # Filesystems

  fileSystems."/" =
    { device = "rpool/nixos";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/AE42-EF0B";
      fsType = "vfat";
    };

  fileSystems."/backup" =
    { device = "rpool/backup";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/nix" =
    { device = "rpool/nixos/nix";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/home" =
    { device = "rpool/userdata/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/root" =
    { device = "rpool/userdata/home/root";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/home/ross" =
    { device = "rpool/userdata/home/ross";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

  fileSystems."/mnt/games" =
    { device = "/dev/disk/by-uuid/38022704-1140-4687-b1b0-d31bd490d17d";
      fsType = "ext4";
    };

  # Users
  home-manager.users.ross.xdg.configFile."kanshi/config".source = ./config/kanshi/config;

  # Steam
  hardware.steam-hardware.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
}
