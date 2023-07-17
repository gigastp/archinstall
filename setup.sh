#!/bin/bash

source ./general.sh;

TIMEREGION=Europe;
TIMECITY=Kiev;
EDITOR=vi;
NETWORKMANAGER=dhcpcd;

function set_locale() {
    echo -e "\nUncomment en_US.UTF-8 UTF-8 and other needed locales";
    echo -n "Edit, then save and close file(press enter to start editing): "; read -s; echo;
    
    ${EDITOR} /etc/locale.gen; locale-gen || return $?;
    echo "LANG=en_US.UTF-8" > /etc/locale.conf;
}

function create_user() {
    echo -en "\nEnter hostname: "; read PCNAME;
    echo ${PCNAME} > /etc/hostname;
    
    echo "Set root password"; passwd;
    while (( $? )); do
        echo -e "\nTry again:"; passwd;
    done
    
    echo -n "Enter username: "; read USERNAME;
    # Probably bug in useradd or pwd (when arg of option -b ended with /):
    # output of pwd after user creation: /home//<username>
    # Note: after `cd ~` pwd showed correct path
    useradd -m -s /bin/bash "${USERNAME}" || return $?;
    
    echo -e "\nSet user($USERNAME) password"; passwd "${USERNAME}";
    while (( $? )); do
        echo -e "\nTry again:"; passwd "${USERNAME}";
    done
    
    echo -e "Appending user to sudoers...";

    TMPFILE=`mktemp`; cat /etc/sudoers > ${TMPFILE}; 
    echo -e "${USERNAME} ALL=(ALL:ALL) ALL\n" > /etc/sudoers; 
    cat ${TMPFILE} >> /etc/sudoers;
}

function install_bootloader() {
    echo && ls /sys/firmware/efi/efivars &> /dev/null;
    if (( $? )); then
        echo -n "Boot dev: "; read BOOTDEV;
        
        grub-install --target=i386-pc /dev/${BOOTDEV};
        while (( $? )); do
            echo -e "\nTry again:\nBoot dev: "; read BOOTDEV;
            grub-install --target=i386-pc /dev/${BOOTDEV};            
        done
    else
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || return $?;
    fi
    
    grub-mkconfig -o /boot/grub/grub.cfg || return $?;
}

function install() {
    msg_beginTask "Installing bootloader..."; install_bootloader || return $?;
    
    msg_beginTask "Configuring timezone...";
    ln -sf /usr/share/zoneinfo/${TIMEREGION}/${TIMECITY} /etc/localtime \
    && hwclock --systohc || return $?;

    msg_beginTask "Configuring locale..."; set_locale || return $?;
    msg_beginTask "Creating user..."; create_user || return $?;

    msg_beginTask "Configuring network...";
    systemctl enable ${NETWORKMANAGER}.service || return $?;

    msg_setupComplated;
}

install;