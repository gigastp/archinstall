TIMEREGION=Europe;
TIMECITY=Kiev;
EDITOR=vi;

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
    arch-chroot /mnt || return $?;

    # Timezone
    ln -sf /usr/share/zoneinfo/${TIMEREGION}/${TIMECITY} /etc/localtime \
    && hwclock --systohc || return $?;

    set_locale || return $?; echo -e "\nLocale configured.";
    create_user || return $?; echo -e "\nUser created.";
}
