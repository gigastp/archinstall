#!/bin/bash

source ./general.sh;

CPUMANUFACTURER=intel;
KERNEL=linux
EDITOR=vi;
EXTRAPACKAGES="${CPUMANUFACTURER}-ucode grub sudo dhcpcd ${EDITOR}\
 bash-completion man-db man-pages texinfo";

function mount_partiotions() {
    echo -n "Boot part: "; read BOOTPART;
    echo -n "System part: "; read SYSPART;
    echo -n "Swap part(empty for skip): "; read SWAPPART;

    umount -q /dev/${BOOTPART} && umount -q /dev/${SYSPART};
    mkfs.fat -F 32 /dev/${BOOTPART} && mkfs.ext4 /dev/${SYSPART} || return $?;    
    mount "/dev/${SYSPART}" /mnt && mount --mkdir "/dev/${BOOTPART}" /mnt/boot || return $?;

    if [ $SWAPPART ]; then
        umount -q /dev/${BOOTPART}; swapon "/dev/${SWAPPART}" || return $?;
    fi
}

function install() {
    msg_beginTask "Mounting partiotions..."; mount_partiotions
    while (( $? )); do
        echo -e "\nTry again:"; mount_partiotions;
    done

    msg_beginTask "Installing system...";
    pacstrap -K /mnt base ${KERNEL} linux-firmware ${EXTRAPACKAGES} || return $?;
    
    msg_beginTask "Creating /etc/fstab..."; genfstab -U /mnt > /mnt/etc/fstab || return $?;
    msg_beginTask "Removing cache files..."; rm -r /var/cache/pacman/pkg/* || return $?;
    msg_beginTask "Entering the chroot enviormant..."; arch-chroot /mnt || return $?;
}

install;
