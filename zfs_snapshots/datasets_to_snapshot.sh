#!/bin/bash

# Sanpshot WindowsComputer dataset
bash /mnt/RussNAS/scripts/zfs_snapshots/manage_snapshots.sh RussNAS/windowsbackups

# Sanpshot plex-media dataset
bash /mnt/RussNAS/scripts/zfs_snapshots/manage_snapshots.sh RussNAS/media