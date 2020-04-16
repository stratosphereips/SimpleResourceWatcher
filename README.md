# Simple Resource Watcher

This simple program is designed to monitor certain resources in a Linux based server and send alerts to Slack. Currently monitoring (i) Network Bandwidth, (ii) Memory Consumption, (iii) Temperature.

## Dependencies

The Simple Resource Watcher usese the following packages:
- curl
- ps
- free
- sensors (Debian package name 'lm-sensors')

## Usage

```
$ srwatcher.sh [network interface] [slack.auth]

Simple Resource Watcher. Version: 0.2
Author: Veronica Valeros (vero.valeros@gmail.com)
```

To get started, move the slack\_example.auth to slack.auth, adding your Slack webhoook URL and Slack channel.

## Limitations

This script reads the network from /sys/class/net/[interface]. This may change depending on the Linux distribution. Please check before attempting to run.
