#!/bin/bash

source ./general.sh;

CPUMANUFACTURER=intel;
KERNEL=linux;
EXTRAPACKAGES="${CPUMANUFACTURER}-ucode grub pam_mount sudo dhcpcd ${EDITOR}\
 bash-completion man-db man-pages texinfo";

function setup_partitions() {
    echo -n "Boot part: "; read BOOTPART;
    echo -n "System part: "; read SYSPART;
    echo -n "Encrypted home part(empty for skip): "; read HOMEPART;
    echo -n "Swap part(empty for skip): "; read SWAPPART;

    umount -q /dev/${BOOTPART} && umount -q /dev/${SYSPART};
    mkfs.${FILESYSTEM} /dev/${SYSPART} && mount "/dev/${SYSPART}" /mnt || return $?;
    # Boot part secure wipe
    cryptsetup open --type plain -d /dev/urandom "/dev/${BOOTPART}" to_be_wiped \
        && dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress \
        && cryptsetup close to_be_wiped || return $?;
    # Boot part encryption
    cryptsetup open "/dev/${BOOTPART}" boot_container \
        && cryptsetup luksFormat "/dev/${BOOTPART}" \
        && mkfs.fat -F 32 /dev/mapper/boot_container \
        && mount -t fat /dev/mapper/boot_container /mnt/boot || return $?;

    if [ "${HOMEPART}" ]; then
        umount -q "/dev/${HOMEPART}";
        # Home part secure wipe
        cryptsetup open --type plain -d /dev/urandom "/dev/${HOMEPART}" to_be_wiped \
            && dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress \
            && cryptsetup close to_be_wiped || return $?;
        # Home part encryption
        cryptsetup open "/dev/${HOMEPART}" home_container \
        && echo "Note: pathphrase must be the same as user password" \
        && cryptsetup luksFormat "/dev/${HOMEPART}" \        
        && mkfs.${FILESYSTEM} /dev/mapper/home_container \
        && mount -t ${FILESYSTEM} /dev/mapper/home_container /mnt/home || return $?;
    fi
    
    if [ "${SWAPPART}" ]; then
        umount -q "/dev/${BOOTPART}"; swapon "/dev/${SWAPPART}" || return $?;
    fi
}

function install() {
    msg_beginTask "Setup partiotions..."; setup_partitions
    while (( $? )); do
        echo -e "\nTry again:"; setup_partitions;
    done

    msg_beginTask "Installing system...";
    pacstrap -K /mnt base ${KERNEL} linux-firmware ${EXTRAPACKAGES} || return $?;
    
    msg_beginTask "Creating /etc/fstab..."; genfstab -U /mnt > /mnt/etc/fstab || return $?;
    msg_beginTask "Removing cache files..."; rm -r /var/cache/pacman/pkg/* || return $?;
    msg_beginTask "Entering the chroot enviormant..."; arch-chroot /mnt || return $?;
}

install;
