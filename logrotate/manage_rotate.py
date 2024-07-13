#!/usr/bin/env python3
import os
import subprocess
import stat

# Function to retrieve the owner, group, and permissions of a given file
def get_file_info(file_path):
    file_stat = os.stat(file_path)
    owner_uid = file_stat.st_uid
    owner_gid = file_stat.st_gid
    permissions = oct(file_stat.st_mode & 0o777)
    return owner_uid, owner_gid, permissions

# Function to set the owner, group, and permissions of a given file
def set_file_info(file_path, owner_uid, owner_gid, permissions):
    os.chown(file_path, owner_uid, owner_gid)
    os.chmod(file_path, int(permissions, 8))

# Main function to process all .conf files in the script's directory
def main():
    script_dir = os.path.dirname(os.path.realpath(__file__))  # Get the directory of the script

    # List all files in the root directory
    for file in os.listdir(script_dir):
        if file.endswith('.conf'):
            file_path = os.path.join(script_dir, file)  # Get the full path of the .conf file
            owner_uid, owner_gid, permissions = get_file_info(file_path)  # Retrieve current file info
            
            try:
                set_file_info(file_path, 0, 0, '600')  # Change owner to root and permissions to 600
                
                subprocess.run(['logrotate', file_path], check=True)  # Run logrotate on the file
            except subprocess.CalledProcessError:
                print(f"Logrotate failed for {file_path}. Restoring original permissions and owners.")
            finally:
                set_file_info(file_path, owner_uid, owner_gid, permissions)  # Restore original file info

if __name__ == "__main__":
    main()
