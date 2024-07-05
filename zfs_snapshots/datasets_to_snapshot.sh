#!/bin/bash

# Sanpshot WindowsComputer dataset
bash /mnt/RussNAS/scripts/zfs_snapshots/manage_snapshots.sh RussNAS/WindowsComputer

# Sanpshot plex-media dataset
bash /mnt/RussNAS/scripts/zfs_snapshots/manage_snapshots.sh RussNAS/plex/plex-media