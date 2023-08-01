#!/bin/bash

source ./general.sh;

CPUMANUFACTURER=intel;
KERNEL=linux;
EXTRAPACKAGES="${CPUMANUFACTURER}-ucode grub efibootmgr pam_mount sudo dhcpcd ${EDITOR}\
 bash-completion man-db man-pages texinfo";

function setup_partitions() {
    echo -n "Boot part: "; read BOOTPART;
    echo -n "System part: "; read SYSPART;
    echo -n "Encrypted home part(empty for skip): "; read HOMEPART;
    echo -n "Swap part(empty for skip): "; read SWAPPART;

    if [ "${FILESYSTEM}" == "btrfs" ]; then
        MKFS="mkfs.btrfs -f";
    else
        MKFS="mkfs.${FILESYSTEM}";
    fi

    umount -q "/dev/${BOOTPART}"; umount -q "/dev/${SYSPART}";
    ${MKFS} "/dev/${SYSPART}" && mount "/dev/${SYSPART}" /mnt || return $?;

    echo && ls /sys/firmware/efi/efivars &> /dev/null;
    if (( $? == 0 )); then
        umount -q "/dev/${EFIPART}"; 

        echo -n "EFI part: "; read EFIPART;
        mkfs.fat -F 32 "/dev/${EFIPART}" \
            && mkdir -p /mnt/efi \
            && mount "/dev/${EFIPART}" /mnt/efi || return $?;

        # Boot part encryption
        cryptsetup open --type plain -d /dev/urandom "/dev/${BOOTPART}" to_be_wiped || return $?;
        dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress;
        cryptsetup close to_be_wiped || return $?;

        cryptsetup --hash sha256 --pbkdf pbkdf2 luksFormat "/dev/${BOOTPART}"  \
            && cryptsetup open "/dev/${BOOTPART}" boot_container \
            && mkdir -p /mnt/boot \
            && mkfs.fat -F 32 /dev/mapper/boot_container \
            && mount /dev/mapper/boot_container /mnt/boot || return $?;
    fi

    if [ "${HOMEPART}" ]; then
        umount -q "/dev/${HOMEPART}";
        # Home part encryption
        cryptsetup open --type plain -d /dev/urandom "/dev/${HOMEPART}" to_be_wiped || return $?;
        dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress;
        cryptsetup close to_be_wiped || return $?;

        echo "Note: pathphrase must be the same as user password";
        cryptsetup  --hash sha256 --pbkdf pbkdf2 luksFormat "/dev/${HOMEPART}" \
            && cryptsetup open "/dev/${HOMEPART}" home_container \
            && ${MKFS} /dev/mapper/home_container || return $?;
    fi
    
    if [ "${SWAPPART}" ]; then
        umount -q "/dev/${SWAPPART}"; swapon "/dev/${SWAPPART}" || return $?;
    fi
}

function install() {
    msg_beginTask "Setup partiotions..."; setup_partitions
    while (( $? )); do
        echo -e "\nTry again:"; setup_partitions;
    done

    msg_beginTask "Installing system...";
    pacstrap -K /mnt base ${KERNEL} linux-firmware ${EXTRAPACKAGES} || return $?;
    
    msg_beginTask "Creating /etc/fstab...";
    umount /mnt/boot && genfstab -U /mnt > /mnt/etc/fstab \
        && mount /dev/mapper/boot_container /mnt/boot || return $?;

    msg_beginTask "Removing cache files..."; rm -r /mnt/var/cache/pacman/pkg/* || return $?;
    msg_beginTask "Entering the chroot enviormant..."; arch-chroot /mnt || return $?;
}

install;
