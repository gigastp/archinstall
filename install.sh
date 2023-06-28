#!/bin/bash

CPUMANUFACTURER=intel;
EDITOR=vi;
EXTRAPACKAGES="${CPUMANUFACTURER}-ucode dhcpcd ufw ${EDITOR} man-db man-pages texinfo";

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
    mount_partiotions
    while (( $? )); do
        echo -e "\nTry again:"; mount_partiotions;
    done

    pacstrap -K /mnt base linux linux-firmware ${EXTRAPACKAGES} || return $?;
    echo -e "\nSystem setup complated.";
    genfstab -U /mnt > /mnt/etc/fstab || return $?; echo -e "\n/etc/fstab: created.";

    arch-chroot /mnt || return $?;
}

install
