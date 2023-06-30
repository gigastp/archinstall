#!bin/bash

function install() {
    pacman -S virtualbox-guest-iso || return $?;
    mount /lib/virtualbox/additions/VBoxGuestAdditions.iso /mnt || return $?;
    /mnt/VBoxLinuxAdditions.run && umount /mnt || return $?;
    pacman -Rscun virtualbox-guest-iso;
}

install