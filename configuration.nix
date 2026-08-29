{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./modules/usb_ethernet.nix
  ];

  system.stateVersion = "26.05";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      bcachefs-tools = prev.bcachefs-tools.overrideAttrs (old: {
        meta = (old.meta or { }) // {
          broken = true;
        };
      });

      uboot-imx = prev.buildUBoot {
        defconfig = "mx6sxlm_defconfig";
        filesToInstall = [ "u-boot-dtb.imx" ];
        extraMeta.platforms = [ "armv7l-linux" ];
        extraPatches = [
          ./patches/001-uboot-add-mx6sxlm-board.patch
        ];
      };

      # u-boot with enabled fastboot to inject u-boot commands from uuu scripts
      uboot-imx-fastboot = prev.buildUBoot {
        defconfig = "mx6sxlm_defconfig";
        filesToInstall = [ "u-boot-dtb.imx" ];
        extraMeta.platforms = [ "armv7l-linux" ];
        extraPatches = [
          ./patches/001-uboot-add-mx6sxlm-board.patch
          ./patches/002-uboot-fastboot.patch
        ];
      };
    })
  ];

  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linux_latest.override {
      defconfig = "imx_v6_v7_defconfig";
      autoModules = false;
    }
  );
  boot.kernelPatches = [
    {
      name = "enable-mmc-block";
      patch = null;
      structuredExtraConfig = with lib.kernel; {
        IOSCHED_BFQ = lib.mkForce yes;
        RPMB = yes;
        MMC_BLOCK = yes;
        IMX_SDMA = yes;
        DAX = yes;
        NETFILTER_XT_MATCH_CONNTRACK = yes;
        NF_CONNTRACK_BRIDGE = yes;
        NF_DEFRAG_IPV4 = yes;
        NF_DEFRAG_IPV6 = yes;
        NETFILTER_XT_MATCH_PKTTYPE = yes;
        NETFILTER_XTABLES = yes;
        IP6_NF_MATCH_RPFILTER = yes;
        IP_NF_IPTABLES = yes;
        IP6_NF_IPTABLES = yes;
        IP_NF_MATCH_RPFILTER = yes;
        NFT_COMPAT = yes;
        NF_CONNTRACK = yes;
        NF_TABLES = yes;
        NETFILTER_NETLINK = yes;
        NET_SCH_FQ_CODEL = yes;
        BLK_DEV_DM = yes;
      };
    }
  ];
  boot.extraModulePackages = [
    (pkgs.callPackage ./pkgs/linux-lin.nix {
      kernel = config.boot.kernelPackages.kernel;
    })
  ];

  hardware.deviceTree.enable = true;
  hardware.deviceTree.dtbSource = pkgs.dtb-imx6sx-lm;
  hardware.deviceTree.name = "imx6sx-lm.dtb";
  hardware.usbEthernet.enable = true;

  boot.kernelParams = [
    "earlycon"
  ];
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.initrd.compressor = "gzip";
  boot.initrd.availableKernelModules = lib.mkForce [ ];

  services.journald.storage = "volatile";

  sdImage = {
    populateFirmwareCommands = "";

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  networking.hostName = "imx";
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;
  systemd.network.networks."90-can0" = {
    matchConfig.Name = "can0";
    canConfig = {
      BitRate = 500000;
    };
  };
  systemd.network.networks."90-sllin0" = {
    matchConfig.Name = "sllin0";
  };

  time.timeZone = "Europe/Prague";

  environment.systemPackages = with pkgs; [
    vim
    htop
    dtc
    tcpdump
    libgpiod
    can-utils
  ];

  services.getty.autologinUser = "root";
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  services.openssh.settings.PasswordAuthentication = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDacshL0MKcPH/C0S7/ybYcd7+643Lo6X9VjAkwdgOCw3FKYWr20qKCHd0hPFXcYixt86aNuF2McNRae5h+dlPwPWIuJTt987gnp25IQlsWBeIiS1tDZI1lZcVu+Yj7BQMmp8uXkyP4KqjX9zaa3FmXv4MeWz/41rRYj72A1ZlsF1H/SxZ7uQX27XuhV5nOvsH2yAbXKexDwcvcR/lrxQcYH9el3QDt6x229lqn9piuSSl/LYAN81jxd/4a2Pwrnqeqca+HC9xY6LF6NW64E2RkZMMTbsaFo8E4FFLnTzcYgP1+EKypPiphMhvCJQLOo3crcxMpv9eOGvgGh8iMdak3"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHPnrZgImCAprHnZQaIyn6Wvvl+YDEjHmm0B8F/TVz57G6E7fHD/Cc8VJ571j1sQ/OeJhSWGm94itmEBBJNx8uoKcVtXvd+7Uow+Ui45KpEGCuMAB+3PdZd6+yzr6yTXr121+//XYAn0bYhAmyijVSMxBZ5gwohmrSg+P2uArhvmuEmn2r5kJ5KCb1tyj2713bhVm/4bFs+q+fHcKRG/0/CyfOPFn8wGfKpjvmmAc1knbzn6zzLOn2tjhA4Y2KEnJuU13ZLvqJLBHXp50LwA0kRDD2irX+6ZJD5KY/JpbzVX5vdgSXUbwAEGeecnU5o7KgXWb61YetRJhi8vu6Q0bxSoG7l1q2XFo8n9mV3TBofFgn4F+nudS9iQ7Cl6To7hi3/0zHnE4M4PVt7idC4BcLyEwGp3rwPApjiuYO7Io3oFTYYv6OORDq788s+FHPDKoHnw2JY/qcEZYQNx9+iIeJhMpBvm2+g7Ysn2NyPoFsB6qg/ZF1TnXdu07t6pngp1E="
  ];

  # reduce image size by disabling features
  hardware.enableAllFirmware = false;
  hardware.enableRedistributableFirmware = lib.mkForce false;

  nix.registry = lib.mkForce { };

  documentation.enable = false;
  documentation.man.man-db.enable = false;

  system.tools.nixos-generate-config.enable = false;
  system.tools.nixos-install.enable = false;
  system.tools.nixos-option.enable = false;
  system.tools.nixos-build-vms.enable = false;
  system.tools.nixos-enter.enable = false;

  system.disableInstallerTools = true;

  security.sudo.enable = false;
  systemd.oomd.enable = false;
  xdg.sounds.enable = false;
  xdg.icons.enable = false;
  fonts.fontconfig.enable = false;
  programs.nano.enable = false;
}
