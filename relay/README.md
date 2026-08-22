# Relay automations

esphome configuration to set boot mode and power cycle i.MX6SX.

```shell-session
$ uvx esphome run relay.yaml
```

Then you can reset board in serial or normal mode from the root:
```shell-session
$ RELAY_HOST=X.X.X.X ./relay.sh serial
```
