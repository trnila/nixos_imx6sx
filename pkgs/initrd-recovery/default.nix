{ pkgs }:

let
  busybox = pkgs.busybox.override {
    enableStatic = true;
  };
in
pkgs.runCommand "recovery-initrd"
  {
    nativeBuildInputs = [
      pkgs.cpio
      pkgs.gzip
    ];
  }
  ''
    mkdir -p root/{bin,dev,proc,sys}

    # copy busybox
    cp ${busybox}/bin/busybox root/bin/busybox

    # make symlinks to busybox
    for cmd in sh mount umount ls ln dmesg cat find grep echo mkdir rm rmdir reboot sync; do
      ln -s busybox root/bin/$cmd
    done

    cp ${./init} root/init

    # generate initrd cpio
    cd root
    find . -print0 | cpio --null -ov --format=newc | gzip -9 > $out
  ''
