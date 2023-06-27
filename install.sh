#!/bin/bash

EXTRAPACKAGES="fsck\
 dhcpcd\
 vi\
 man-db man-pages texinfo";
TIMEREGION=Europe;
TIMECITY=Kiev;
EDITOR=vi;

function mount_partiotions() {
    echo -n "Boot part: "; read BOOTPART;
    echo -n "System part: "; read SYSPART;
    echo -n "Swap part(empty for skip): "; read SWAPPART;

    umount -q /dev/${BOOTPART} && umount -q /dev/${SYSPART};
    mount "/dev/${SYSPART}" /mnt && mount --mkdir "/dev/${BOOTPART}" /mnt/boot || return $?;

    mkfs.fat -F 32 /dev/${BOOTPART} && mkfs.ext4 /dev/${SYSPART} || return $?;

    if [ $SWAPPART ]; then
        umount -q /dev/${BOOTPART}; swapon "/dev/${SWAPPART}" || return $?;
    fi
}

function set_locale() {
    echo "Uncomment en_US.UTF-8 UTF-8 and other needed locales";
    echo -n "Edit, then save file(press enter to start editing): "; read -s; echo;
    ${EDITOR} /etc/locale.conf; locale-gen || return $?;
    echo "LANG=en_US.UTF-8" > /etc/locale.conf;
}

function create_user() {
    echo -n "Enter hostname: "; read PCNAME;
    echo -n "Enter username: "; read USERNAME;

    useradd -m -s /bin/bash ${USERNAME} || return $?;
    passwd ${USERNAME};
    while (( $? )); do
        echo -e "\nTry again:"; passwd ${USERNAME};
    done

    TMPFILE=`mktemp`; echo -e "${USERNAME} ALL=(ALL:ALL) ALL\n" > ${TMPFILE};
}

function install() {
    mount_partiotions
    while (( $? )); do
        echo -e "\nTry again:"; mount_partiotions;
    done

    pacstrap -K /mnt base linux linux-firmware ${EXTRAPACKAGES} || return $?;
    genfstab -U /mnt > /mnt/etc/fstab || return $?; echo "/etc/fstab created.";

    arch-chroot /mnt || return $?;

    # Timezone
    ln -sf /usr/share/zoneinfo/${TIMEREGION}/${TIMECITY} /etc/localtime \
    && hwclock --systohc || return $?;
}

install
