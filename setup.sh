#!/bin/bash

source ./general.sh;

TIMEREGION=Europe;
TIMECITY=Kiev;
NETWORKMANAGER=dhcpcd;
BOOTDEV="";

function set_locale() {
    echo -e "\nUncomment en_US.UTF-8 UTF-8 and other needed locales";
    echo -n "Edit, then save and close file(press enter to start editing): "; read -s; echo;
    
    ${EDITOR} /etc/locale.gen; locale-gen || return $?;
    echo "LANG=en_US.UTF-8" > /etc/locale.conf;
}

function create_user() {
    echo -en "\nEnter hostname: "; read PCNAME;
    echo "${PCNAME}" > /etc/hostname;
    
    echo "Set root password"; passwd;
    while (( $? )); do
        echo -e "\nTry again:"; passwd;
    done

    echo -n "Enter username: "; read USERNAME;
    useradd -m -s /bin/bash "${USERNAME}" || return $?;
    echo -en "\nNote: if you use encrypted /home part, user password must be the same ";
    echo -e "as pathphrase for encrypted part;"

    echo "Set user(${USERNAME}) password"; passwd "${USERNAME}";
    while (( $? )); do
        echo -e "\nTry again:"; passwd "${USERNAME}";
    done

    if [ -a /dev/mapper/home_container ]; then
        echo "Setup login time mounting for /home..."; $(exit 1);
        while (( $? )); do
            echo -n "Home part: "; read HOMEPART;        
            HOMEPART_UUID=`cryptsetup luksUUID "/dev/${HOMEPART}"` && break;
            echo -e "\nTry Again:"; $(exit 1);
        done
        
        # Configuring pam_mount
        cat << EOF > /etc/security/pam_mount.conf.xml
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE pam_mount SYSTEM "pam_mount.conf.xml.dtd">

<!-- See pam_mount.conf(5) for a description. -->
<pam_mount>
		<!-- debug should come before everything else,
		since this file is still processed in a single pass
		from top-to-bottom -->
        
<debug enable="0" />
		<!-- Volume definitions -->

		<volume user="${USERNAME}" path="/dev/disk/by-uuid/${HOMEPART_UUID}"
			fstype="crypt" mountpoint="~" />

		<!-- pam_mount parameters: General tunables -->
<!-- 
<luserconf name=".pam_mount.conf.xml" />
-->

<!-- Note that commenting out mntoptions will give you the defaults.
     You will need to explicitly initialize it with the empty string
     to reset the defaults to nothing. -->

<mntoptions allow="nosuid,nodev,loop,encryption,fsck,nonempty,allow_root,allow_other" />

<!--
<mntoptions deny="suid,dev" />
<mntoptions allow="*" />
<mntoptions deny="*" />
-->

<mntoptions require="nosuid,nodev" />

<!-- requires ofl from hxtools to be present -->
<logout wait="0" hup="no" term="no" kill="no" />

		<!-- pam_mount parameters: Volume-related -->

<mkmountpoint enable="1" remove="true" />

</pam_mount>
EOF
        # Adding pam_mount to login modules + avoid double mount error
        cat << EOF > /etc/pam.d/system-login
#%PAM-1.0

auth       required   pam_shells.so
auth       requisite  pam_nologin.so
auth       optional   pam_mount.so
auth       include    system-auth

account    required   pam_access.so
account    required   pam_nologin.so
account    include    system-auth

password   optional   pam_mount.so
password   include    system-auth

session    optional   pam_loginuid.so
session    optional   pam_keyinit.so       force revoke
session [success=1 default=ignore]  pam_succeed_if.so  service = systemd-user quiet
session    optional   pam_mount.so
session    include    system-auth
session    optional   pam_motd.so          motd=/etc/motd
session    optional   pam_mail.so          dir=/var/spool/mail standard quiet
-session   optional   pam_systemd.so
session    required   pam_env.so
EOF
    fi
    
    echo -e "Appending user to sudoers...";
    TMPFILE=`mktemp`; cat /etc/sudoers > ${TMPFILE}; 
    echo -e "${USERNAME} ALL=(ALL:ALL) ALL\n" > /etc/sudoers; 
    cat ${TMPFILE} >> /etc/sudoers;
}

function install_bootloader() {
    echo && ls /sys/firmware/efi/efivars &> /dev/null;
    if (( $? == 0 )); then
        echo -e "Enabling boot encryption..."
        TMPFILE=`mktemp`; cat /etc/default/grub > ${TMPFILE};
        echo -e "GRUB_ENABLE_CRYPTODISK=y\n" > /etc/default/grub;
        cat ${TMPFILE} >> /etc/default/grub;

        grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB || return $?;
    else
        ($exit 1);
    fi

    while (( $? )); do
        echo -n "Boot part: "; read BOOTPART;
        grub-install --target=i386-pc "/dev/${BOOTPART}" && break;
        echo "Try Again: "; $(exit 1);
    done
    
    grub-mkconfig -o /boot/grub/grub.cfg || return $?;
}

function install() {
    msg_beginTask "Configuring timezone...";
    ln -sf /usr/share/zoneinfo/${TIMEREGION}/${TIMECITY} /etc/localtime \
    && hwclock --systohc || return $?;

    msg_beginTask "Configuring locale..."; set_locale || return $?;
    msg_beginTask "Creating user..."; create_user || return $?;
    msg_beginTask "Installing bootloader..."; install_bootloader || return $?;

    msg_beginTask "Configuring network...";
    systemctl enable ${NETWORKMANAGER}.service || return $?;

    msg_setupCompleted;
}

install;