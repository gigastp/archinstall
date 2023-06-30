#!bin/bash

function install() {
    pacman -S virtualbox-guest-iso || return $?;
    umount -q /mnt; mount /lib/virtualbox/additions/VBoxGuestAdditions.iso /mnt || return $?;
    /mnt/VBoxLinuxAdditions.run || return $?;
    umount /mnt && pacman -Rscun virtualbox-guest-iso;
    echo -e "\n< Setup complated >";
}

install