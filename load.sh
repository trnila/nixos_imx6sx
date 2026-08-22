#!/usr/bin/env bash
target="$1"
if [ -z "$1" ]; then
    echo "Usage: $0 target"
    exit 1
fi

set -ex

./relay.sh serial
nix build .#"$1"
sudo uuu ./result/script.lst
