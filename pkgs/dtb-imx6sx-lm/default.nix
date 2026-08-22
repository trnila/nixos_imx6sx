{ pkgs, lib }:

let
  kernel = pkgs.linux;
  native = pkgs.buildPackages;
in
pkgs.stdenv.mkDerivation {
  pname = "dtb-imx6sx-lm";
  version = "1.0";

  src = pkgs.linux.src;

  nativeBuildInputs = [
    native.dtc
    native.gcc
  ];

  buildPhase = ''
    "$CC" \
      -E \
      -nostdinc \
      -I arch/arm/boot/dts \
      -I arch/arm/boot/dts/nxp/imx \
      -I include \
      -I arch/arm/include \
      -undef \
      -x assembler-with-cpp \
      ${./dtb-imx6sx-lm.dts} > preprocessed.dts

    dtc \
      -@ \
      -I dts \
      -O dtb \
      -o imx6sx-lm.dtb \
      preprocessed.dts
  '';

  installPhase = ''
    mkdir -p $out
    cp imx6sx-lm.dtb $out/
  '';
}
