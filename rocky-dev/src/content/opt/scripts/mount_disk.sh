#!/bin/bash
set -e

disk=$1
point=$2

mkdir -p ${point}
if [[ `grep -c "${disk} ${point}" /etc/fstab` -eq 0 ]]; then
    echo "${disk} ${point}                   xfs     defaults        0 0" >> /etc/fstab
fi

if [[ `mount | grep -c "${point}"` -eq 0 ]]; then
    mount ${point}
fi
