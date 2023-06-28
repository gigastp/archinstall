#!/bin/bash

CPUMANUFACTURER=intel;
EDITOR=vi;
EXTRAPACKAGES="${CPUMANUFACTURER}-ucode grub sudo dhcpcd ufw ${EDITOR} man-db man-pages texinfo";

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

function install_bootloader() {
    ls /sys/firmware/efi/efivars &> /dev/null;
    if (( $? )); then
        echo -n "Boot dev: "; read BOOTDEV;
        
        grub-install --target=i386-pc /dev/${BOOTDEV};
        while (( $? )); do
            echo -e "\nTry Again:\nBoot dev: "; read BOOTDEV;
            grub-install --target=i386-pc /dev/${BOOTDEV};            
        done
    else
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || return $?;
    fi
    
    grub-mkconfig -o /boot/grub/grub.cfg || return $?;
}

function install() {
    mount_partiotions
    while (( $? )); do
        echo -e "\nTry again:"; mount_partiotions;
    done

    pacstrap -K /mnt base linux linux-firmware ${EXTRAPACKAGES} || return $?;
    echo -e "System setup completed.";
    genfstab -U /mnt > /mnt/etc/fstab || return $?; echo -e "/etc/fstab created.";
    install_bootloader || return $?; echo -e "Bootloader installed.\n";    

    echo -e "Entering in chroot..."; arch-chroot /mnt || return $?;
}

install
