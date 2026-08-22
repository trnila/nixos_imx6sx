#!/usr/bin/env bash
boot="$1"

if [ "$boot" != "normal" ] && [ "$boot" != "serial" ]; then
    echo "Usage: $0 boot_mode[normal|serial]"
    exit 1
fi

if [ -z "$RELAY_HOST" ]; then
    echo "Set boot mode to $boot and then power cycle..."
else

    relay() {
        name="$1"
        state="$2"
        curl -X POST -H"Content-Length:0" "$RELAY_HOST/switch/$name/turn_$state"
    }

    relay power off
    [[ "$boot" == "serial" ]] && boot_relay=off || boot_relay=on
    relay boot "$boot_relay"
    relay power on
fi
