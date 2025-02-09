
# Multi-Partition Project

This project contains scripts to manage and initialize different Linux kernel versions and root filesystem partitions.

## Scripts

### `restore_version.sh`

This script sets the specified Linux kernel version as the default for the next system boot.

Usage:
```bash
./restore_version.sh <kernel_version>
```

### `initialize_rootfs.sh`

This script initializes the root filesystem by mounting the partition, copying the active root filesystem squash file, and unmounting the partition.

Usage:
```bash
./initialize_rootfs.sh
```

### `etc/grub.d/40_custom`

This file contains custom GRUB menu entries for different Linux kernel versions.

Example entries:
```bash
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
