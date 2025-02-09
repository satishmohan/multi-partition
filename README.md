# Multi-Partition Project

This project contains scripts to manage and initialize different Linux kernel versions and root filesystem partitions with encryption.

## Prerequisites

Ensure you have the necessary packages installed:

```
# bash
sudo apt-get update
sudo apt-get install cryptsetup clevis clevis-luks
```

## GRUB Configuration
Ensure the /etc/grub.d/40_custom file includes entries for different kernel versions. For example:

```
# filepath: /etc/grub.d/40_custom
menuentry 'Linux Version 1' {
    set root='(hd0,1)'
    linux /vmlinuz-1 root=/dev/sda2 ro
    initrd /initrd.img-1
}

menuentry 'Linux Version 2' {
    set root='(hd0,1)'
    linux /vmlinuz-2 root=/dev/sda2 ro
    initrd /initrd.img-2
}
```

## Script to Handle New Kernel Installation
The script install_new_kernel.sh handles the installation of a new kernel and update the GRUB configuration.

```
# filepath: /Users/samohan/Code/multi-partition/scripts/install_new_kernel.sh
#!/bin/bash

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
```

## Utility to Restore Previous Versions

The script restore_version.sh is used to restore a previous version.

```
# filepath: /Users/samohan/Code/multi-partition/scripts/restore_version.sh
#!/bin/bash

KERNEL_VERSION=$1

if [ -z "$KERNEL_VERSION" ]; then
    echo "Usage: $0 <kernel_version>"
    exit 1
fi

# Update GRUB to set the specified version as the default
grub-set-default "Linux Version $KERNEL_VERSION"
update-grub

echo "System will boot into Linux Version $KERNEL_VERSION on next reboot."
```

## Script to Initialize Root Filesystem with Encryption

### Option 1: LUKS on Partition

The script initialize_rootfs.sh is configured to run on reboot after installation.

```
# filepath: /Users/samohan/Code/multi-partition/scripts/initialize_rootfs.sh
#!/bin/bash
# 

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
```

### Option 2: LVM on LUKS

In this option the script initialize_rootfs_lvm.sh is as follows:

```
# Encrypt the root filesystem partition
cryptsetup luksFormat /dev/sda2

# Open the encrypted partition
cryptsetup open /dev/sda2 cryptlvm

# Bind the LUKS key to the TPM
clevis luks bind -d /dev/sda2 tpm2 '{"pcr_ids":"7"}'

# Create LVM physical volume
pvcreate /dev/mapper/cryptlvm

# Create LVM volume group
vgcreate vg0 /dev/mapper/cryptlvm

# Create LVM logical volume
lvcreate -L 20G -n root vg0

# Format the logical volume
mkfs.ext4 /dev/vg0/root

# Mount the logical volume
mount /dev/vg0/root /mnt

# Copy the current active rootfs squash file to the root filesystem partition
unsquashfs -f -d /mnt /path/to/active/rootfs.squashfs

# Unmount the partition
umount /mnt

# Close the encrypted partition
cryptsetup close cryptlvm

echo "Root filesystem initialized and encrypted with LVM."
```

### Initramfs Configuration

Ensure the initramfs is configured to unlock the encrypted partition at boot. Add the necessary hooks:

```
# filepath: /Users/samohan/Code/multi-partition/scripts/etc/initramfs-tools/hooks/clevis
#!/bin/sh
PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions

copy_exec /usr/bin/clevis
copy_exec /usr/bin/cryptsetup
```

Update the initramfs:

```
sudo update-initramfs -u
```

## GRUB Configuration for Encrypted Root Filesystem

Ensure the GRUB configuration is set up to unlock the encrypted partition at boot. Add the following to the GRUB configuration:

```
# filepath: /etc/default/grub
GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda2:cryptroot root=/dev/mapper/cryptroot"
```

Then update GRUB:

```
sudo update-grub
```

## Automate Script Execution on Reboot

Add initialize_rootfs.sh or initialize_rootfs_lvm.sh to the system's startup scripts. For example, we can add it to /etc/rc.local:

```
# filepath: /etc/rc.local
/Users/samohan/Code/multi-partition/scripts/initialize_rootfs.sh
```

or

```
# filepath: /etc/rc.local
/Users/samohan/Code/multi-partition/scripts/initialize_rootfs_lvm.sh
```

This setup will provide the functionality for managing multiple kernel versions and root filesystems with encryption using LUKS and TPM.















