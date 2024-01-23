# Get list of backups, and figure out which ones are needed
from datetime import date
import os

data_file = open("backup_list.txt")
backup_files = data_file.readlines()
backup_vm = {}


for line in backup_files:
    
    # First split the filename into its parts
    parts = line.split("-")
     
    # Now extract those parts into something useful
    vid = parts[2]
    current_date = parts[3]
    current_time = parts[4]
    
    # If the entry doesnt exist, add it
    # else compare the dates and see which one is newer
    if vid not in backup_vm:
        backup_vm[vid] = line
    else:
        old_date = backup_vm[vid].split("-")[3]
        old_time = backup_vm[vid].split("-")[4]
        print(old_date)
        old_datestamp = date(int(old_date.split('_')[0]), int(old_date.split('_')[1]), int(old_date.split('_')[2]))
        current_datestamp = date(int(current_date.split('_')[0]), int(current_date.split('_')[1]), int(current_date.split('_')[2]))
        
        if current_datestamp > old_datestamp:
            backup_vm[vid] = line
    
        
# Try to backup the files
for vid in backup_vm:
    print("qmrestore " + backup_vm[vid].rstrip("\n") + " " + vid)
    os.system("qmrestore " + backup_vm[vid].rstrip("\n") + " " + vid)