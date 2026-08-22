#!/usr/bin/env bash
set -ex
nixos-rebuild --flake .#imx6sx-lm --target-host imx --no-reexec switch
