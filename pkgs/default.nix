final: prev: {
  initrd-recovery = final.callPackage ./initrd-recovery { };
  dtb-imx6sx-lm = final.callPackage ./dtb-imx6sx-lm { };
}
