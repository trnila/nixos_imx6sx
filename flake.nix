{
  #inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      system = nixpkgs.lib.nixosSystem {
        system = "armv7l-linux";
        modules = [
          {
            nixpkgs.buildPlatform = "x86_64-linux";
            nixpkgs.hostPlatform = "armv7l-linux";
          }

          {
            nixpkgs.overlays = [
              (import ./pkgs)
            ];
          }

          (
            { modulesPath, ... }:
            {
              imports = [
                "${modulesPath}/installer/sd-card/sd-image.nix"
              ];
              sdImage.compressImage = false;
            }
          )

          ./configuration.nix

        ];

      };
    in
    {
      nixosConfigurations.imx6sx-lm = system;

      recovery = system.pkgs.runCommand "recovery" { } ''
        mkdir -p $out
        cp ${system.config.boot.kernelPackages.kernel}/zImage $out/
        cp ${system.pkgs.uboot-imx-fastboot}/u-boot-dtb.imx $out/
        cp ${system.pkgs.dtb-imx6sx-lm}/imx6sx-lm.dtb $out/
        cp ${system.pkgs.initrd-recovery} $out/initrd
        cp ${./recovery.lst} $out/script.lst
      '';
      uboot = system.pkgs.runCommand "uboot" { } ''
        mkdir -p $out
        cp ${system.config.boot.kernelPackages.kernel}/zImage $out/
        cp ${system.pkgs.uboot-imx}/u-boot-dtb.imx $out/
        cp ${system.pkgs.dtb-imx6sx-lm}/imx6sx-lm.dtb $out/
        cp ${./uboot.lst} $out/script.lst
      '';

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nixos-rebuild
              pkgs.prek
              pkgs.uuu
            ];
          };
        }
      );
    };
}
