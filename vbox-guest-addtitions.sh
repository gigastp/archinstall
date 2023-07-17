#!bin/bash

source ./general.sh;

function install() {
    pacman -S virtualbox-guest-iso || return $?;
    umount -q /mnt; mount /lib/virtualbox/additions/VBoxGuestAdditions.iso /mnt || return $?;
    /mnt/VBoxLinuxAdditions.run; 
    umount /mnt && pacman -Rscun virtualbox-guest-iso;

    msg_setupCompleted;
}

install;