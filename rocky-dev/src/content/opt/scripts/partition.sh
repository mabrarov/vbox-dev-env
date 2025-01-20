#!/bin/bash -eux

disk=$1
partition=${disk}1

if [[ `fdisk -l ${disk} | grep -c "${partition}"` -ne 0 ]]; then
  exit 0
fi

echo "Creating partition ${partition}"

fdisk ${disk} <<FDISK
n
p
1


w
FDISK

if [[ `fdisk -l ${disk} | grep -c "${partition}"` -ne 1 ]]; then
  echo "Failed to create partition ${partition}"
  exit 1
fi

mkfs.xfs ${partition}
