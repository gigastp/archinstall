#!/bin/bash

TIMEREGION=Europe;
TIMECITY=Kiev;
EDITOR=vi;
NETWORKMANAGER=dhcpcd;

function set_locale() {
    echo "Uncomment en_US.UTF-8 UTF-8 and other needed locales";
    echo -n "Edit, then save file(press enter to start editing): "; read -s; echo;
    
    ${EDITOR} /etc/locale.gen; locale-gen || return $?;
    echo "LANG=en_US.UTF-8" > /etc/locale.conf;
}

function create_user() {
    echo -n "Enter hostname: "; read PCNAME;
    echo -n "Enter username: "; read USERNAME;
    
    echo ${PCNAME} > /etc/hostname;
    useradd -m -s /bin/bash -b "/home/ "${USERNAME}" || return $?;

    echo "Set root password:"; passwd;
    while (( $? )); do
        echo -e "\nTry Again"; passwd;
    done

    echo -e "\nSet user password:"; passwd "${USERNAME}";
    while (( $? )); do
        echo -e "\nTry again:"; passwd "${USERNAME}";
    done
    
    TMPFILE=`mktemp`; cat /etc/sudoers > ${TMPFILE}; echo -e "${USERNAME} ALL=(ALL:ALL) ALL\n" > /etc/sudoers;
    cat ${TMPFILE} >> /etc/sudoers; echo -e "User appended to sudoers.";
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
    install_bootloader || return $?; echo -e "Bootloader installed.\n";
    
    # Timezone
    ln -sf /usr/share/zoneinfo/${TIMEREGION}/${TIMECITY} /etc/localtime \
    && hwclock --systohc || return $?; echo -e "Timezone setup completed.\n";

    set_locale || return $?; echo -e "Locale configured.\n"; 
    create_user || return $?; echo -e "User created.\n";

    # Network
    systemctl enable ${NETWORKMANAGER}.service || return $? && echo -e "Network configured.\n";
}

install
