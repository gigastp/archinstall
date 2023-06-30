#!bin/bash

function install() {
    pacman -S virtualbox-guest-iso || return $?;
    mount /lib/virtualbox/additions/VBoxGuestAdditions.iso || return $?;
    /mnt/VBoxLinuxAdditions.run && umount /mnt || return $?
}

install