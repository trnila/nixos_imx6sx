{
  stdenv,
  lib,
  pkgs,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation {
  pname = "linux-lin";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "lin-bus";
    repo = "linux-lin";
    rev = "98d86acb69e2030e9ad8c1537df07a70ad4173c9";
    hash = "sha256-DeId+ANuHnFQifc2PWXS9lH0/2FHNK5unYA0rtocxhQ=";
  };
  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    cd sllin
    export CROSS_COMPILE=${stdenv.cc.targetPrefix}
    export ARCH=${stdenv.hostPlatform.linuxArch}
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) modules
  '';

  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    cp sllin.ko $out/lib/modules/${kernel.modDirVersion}/extra/
  '';
}
