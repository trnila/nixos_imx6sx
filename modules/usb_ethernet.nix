{ config, lib, ... }:

let
  cfg = config.hardware.usbEthernet;
in
{
  options.hardware.usbEthernet.enable = lib.mkEnableOption "USB Ethernet gadget";

  config = lib.mkIf cfg.enable {
    systemd.services.usb-ethernet = {
      description = "USB Ethernet";

      wantedBy = [ "multi-user.target" ];
      after = [ "sys-kernel-config.mount" ];
      before = [ "network-pre.target" ];
      wants = [ "network-pre.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -eux

        G=/sys/kernel/config/usb_gadget/g1
        mkdir -p "$G"

        echo 0x1209 > "$G/idVendor"
        echo 0x0001 > "$G/idProduct"

        mkdir -p "$G/strings/0x409"
        echo "0001" > "$G/strings/0x409/serialnumber"
        echo "trnila" > "$G/strings/0x409/manufacturer"
        echo "USB Ethernet" > "$G/strings/0x409/product"

        mkdir -p "$G/configs/c.1/strings/0x409"
        echo "USB Ethernet" > "$G/configs/c.1/strings/0x409/configuration"

        mkdir -p "$G/functions/ecm.usb0"
        ln -s "$G/functions/ecm.usb0" "$G/configs/c.1/ecm.usb0"

        UDC=$(ls /sys/class/udc | head -n1)
        if [ -z "$UDC" ]; then
          echo "No USB device controller found" >&2
          exit 1
        fi
        echo "$UDC" > "$G/UDC"
      '';
    };

    systemd.network = {
      enable = true;

      networks."90-usb0" = {
        matchConfig.Name = "usb0";
        address = [
          "10.0.0.1/24"
        ];
      };
    };
  };
}
