@echo off
set "PATH=%ProgramFiles%\Oracle\VirtualBox;%PATH%"
set VM_NAME=dev
VBoxManage storageattach "%VM_NAME%" --storagectl SATA --port 1 --device 0 --type hdd --medium none
VBoxManage storageattach "%VM_NAME%" --storagectl SATA --port 2 --device 0 --type hdd --medium none
VBoxManage storageattach "%VM_NAME%" --storagectl SATA --port 3 --device 0 --type hdd --medium none
