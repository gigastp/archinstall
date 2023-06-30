#!bin/bash

pacman -S virtualbox-guest-iso;
mount /lib/virtualbox/additions/VBoxGuestAdditions.iso;
/mnt/VBoxLinuxAdditions.run;
umount /mnt;