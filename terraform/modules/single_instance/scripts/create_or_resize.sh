#!/bin/bash
DEVICE=$1
MOUNTPOINT=$2
FILESYSTEM=$3

if ! sudo blkid -o value -s TYPE "${DEVICE}";then
    sudo mkfs -t "${FILESYSTEM}" "${DEVICE}"
    sudo mkdir -p "/mnt/${MOUNTPOINT}"
    sudo mount "${DEVICE}" "/mnt/${MOUNTPOINT}"
fi
resize2fs "${DEVICE}" 
