# Nix on i.MX6

NixOS configuration for custom board with i.MX6SX.

## Install on eMMC
1. Load recovery image onto the board via `uuu`:
   ```shell-session
   $ ./load.sh recovery
   ```
   If you are having relays connected, set environment variable `RELAY_HOST=X.X.X.X`.
2. Build eMMC image and write it to the disk exposed via recovery image:
   ```shell-session
   $ nix build .#nixosConfigurations.imx6sx-lm.config.system.build.sdImage
   $ sudo dd if=result/sd-image/nixos-image-sd-card-26.11.20260722.72cf9fa-armv7l-linux.img of=/dev/sdX status=progress
   ```
3. Build and copy u-boot bootloader:
   ```shell-session
   $ nix build .#nixosConfigurations.imx6sx-lm.pkgs.uboot-imx
   $ sudo dd if=result/u-boot-dtb.imx of=/dev/sdX bs=1K seek=1 conv=fsync
   ```

## Switch to the new NixOS configuration
1. Connect USB cable to the board to create Ethernet over USB interface
2. Set `10.0.0.2/24` on your computer
3. Create ssh config in ~/.ssh/config
   ```shell-session
   Host imx
        User root
        HostName 10.0.0.1
   ```
4. Switch to the new configuration
   ```shell-session
   $ ./deploy.sh
   ```

## Load uboot/kernel/initrd during development
```shell-session
$ ./load.sh uboot
```
