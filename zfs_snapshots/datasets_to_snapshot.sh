#!/bin/bash

# Snapshot test dataset
bash /mnt/RussNAS/scripts/zfs_snapshots/zfs_snapshot.sh RussNAS/test

# Sanpshot WindowsComputer dataset
bash /mnt/RussNAS/scripts/zfs_snapshots/zfs_snapshot.sh RussNAS/WindowsComputer

# Sanpshot plex-media dataset
bash /mnt/RussNAS/scripts/zfs_snapshots/zfs_snapshot.sh RussNAS/plex/plex-media