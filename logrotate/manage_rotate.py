#!/usr/bin/env python3
import os
import subprocess
import stat

def get_file_info(file_path):
    file_stat = os.stat(file_path)
    owner_uid = file_stat.st_uid
    owner_gid = file_stat.st_gid
    permissions = oct(file_stat.st_mode & 0o777)
    return owner_uid, owner_gid, permissions

def set_file_info(file_path, owner_uid, owner_gid, permissions):
    os.chown(file_path, owner_uid, owner_gid)
    os.chmod(file_path, int(permissions, 8))

def main():
    script_dir = os.path.dirname(os.path.realpath(__file__))

    for root, _, files in os.walk(script_dir):
        for file in files:
            if file.endswith('.conf'):
                file_path = os.path.join(root, file)
                owner_uid, owner_gid, permissions = get_file_info(file_path)
                
                set_file_info(file_path, 0, 0, '600')  # Change owner to root and permissions to 600
                
                subprocess.run(['logrotate', file_path], check=True)
                
                set_file_info(file_path, owner_uid, owner_gid, permissions)

if __name__ == "__main__":
    main()
