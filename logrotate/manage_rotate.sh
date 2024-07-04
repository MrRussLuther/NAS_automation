#!/bin/bash

# Rotate test log file
logrotate /mnt/RussNAS/scripts/logrotate/rotate_test.conf

# Rotate WindowsComputer log file
logrotate /mnt/RussNAS/scripts/logrotate/rotate_WindowsComputer.conf

# Rotate plex-media log file
logrotate /mnt/RussNAS/scripts/logrotate/rotate_plex-media.conf

# Rotate organize_dji_files log file
logrotate /mnt/RussNAS/scripts/logrotate/rotate_organize_dji_files.conf
