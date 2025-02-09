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

# Encrypt the root filesystem partition
cryptsetup luksFormat /dev/sda2

# Open the encrypted partition
cryptsetup open /dev/sda2 cryptroot

# Bind the LUKS key to the TPM
clevis luks bind -d /dev/sda2 tpm2 '{"pcr_ids":"7"}'

# Format the encrypted partition
mkfs.ext4 /dev/mapper/cryptroot

# Mount the encrypted partition
mount /dev/mapper/cryptroot /mnt

# Copy the current active rootfs squash file to the root filesystem partition
unsquashfs -f -d /mnt /path/to/active/rootfs.squashfs

# Unmount the partition
umount /mnt

# Close the encrypted partition
cryptsetup close cryptroot

echo "Root filesystem initialized and encrypted."