#!/bin/bash
# 
# Copyright (c) 2025, Satish Mohan
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF


KERNEL_VERSION=$1
ROOTFS_SQUASH=$2

if [ -z "$KERNEL_VERSION" ] || [ -z "$ROOTFS_SQUASH" ]; then
    echo "Usage: $0 <kernel_version> <rootfs_squash>"
    exit 1
fi

# Copy the new kernel to the boot partition
cp /path/to/kernels/vmlinuz-$KERNEL_VERSION /boot/vmlinuz-$KERNEL_VERSION
cp /path/to/kernels/initrd.img-$KERNEL_VERSION /boot/initrd.img-$KERNEL_VERSION

# Update GRUB configuration
cat <<EOF >> /etc/grub.d/40_custom
menuentry 'Linux Version $KERNEL_VERSION' {
    set root='(hd0,1)'
    linux /vmlinuz-$KERNEL_VERSION root=/dev/sda2 ro
    initrd /initrd.img-$KERNEL_VERSION
}
EOF

update-grub

# Create and initialize the root filesystem partition
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
unsquashfs -f -d /mnt $ROOTFS_SQUASH
umount /mnt

echo "Kernel $KERNEL_VERSION installed and root filesystem initialized."