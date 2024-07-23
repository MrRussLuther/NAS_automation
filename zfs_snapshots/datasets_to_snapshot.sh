#!/bin/bash

# Sanpshot WindowsComputer dataset
bash /mnt/russnas/scripts/zfs_snapshots/manage_snapshots.sh russnas/windowsbackups

# Sanpshot plex-media dataset
bash /mnt/russnas/scripts/zfs_snapshots/manage_snapshots.sh russnas/media