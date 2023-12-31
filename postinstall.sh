#!/bin/bash

source ./general.sh;

GPUDRIVER=nvidia;
DISPLAYMANAGER=lightdm;
DESKTOPENVIRONMANT=plasma;
SOUNDMANAGER=pulseaudio;

TERMINALAPPS="ufw clamav vim mc ranger ncdu htop neofetch";
BASICAPPS="xfce4-terminal firefox thunar file-roller clamtk xed lximage-qt kolourpaint xreader djview vlc audacious libreoffice-still gimp qbittorrent";
DEVELOPAPPS="gcc gdb make cmake git sqlite sqlitebrowser code qtcreator qt5-doc";
TOOLAPPS="cherrytree flameshot kdeconnect";
INTERNETAPPS="wireshark-qt telegram-desktop discord";
GAMEAPPS="steam wine dolphin-emu lutris";
OTHERAPPS="virtualbox";
TOINSTALL="${GPUDRIVER} ${DESKTOPENVIRONMANT} ${SOUNDMANAGER} ${TERMINALAPPS} ${BASICAPPS}\
 ${DEVELOPAPPS} ${TOOLAPPS} ${INTERNETAPPS} ${GAMEAPPS} ${OTHERAPPS}";

function install_packages() {
    if [ ${DISPLAYMANAGER} ]; then
        TOINSTALL="${TOINSTALL} ${DISPLAYMANAGER}";
        if [ ${DISPLAYMANAGER} == "lightdm" ]; then
            TOINSTALL="${TOINSTALL} lightdm-gtk-greeter";
        fi  
    fi

    if [ ${DESKTOPENVIRONMANT} == "i3-wm" ]; then
        TOINSTALL="${TOINSTALL} i3status xorg-server xorg-xinit pavucontrol";
    fi

    if [ ${SOUNDMANAGER} == "pulseaudio" ]; then
        TOINSTALL="${TOINSTALL} pulseaudio-alsa";
    
        if [ ${DESKTOPENVIRONMANT} == "xfce4" ]; then
            TOINSTALL="${TOINSTALL} pavucontrol xfce4-pulseaudio-plugin";
        fi
    fi

    echo "Some packages may nead 32-bit dependency, to install them you nead enable ";
    echo -e "multilib repo.\n\nUncomment [multilib] section, then save and close file.";
    echo -n "Press enter to start editing:"; read -s; echo;

    ${EDITOR} /etc/pacman.conf && pacman -Sy ${TOINSTALL};
    while (( $? )); do
        echo -n "Try again(press enter to start editing):"; read -s; echo;
        ${EDITOR} /etc/pacman.conf && pacman -Sy ${TOINSTALL};
    done
}

function apps_setup() {
    if ( contains "${TOINSTALL}" "clamav" ); then
        msg_beginTask "Configuring clamav...";

        systemctl enable clamav-freshclam.service clamav-daemon.service \
            && freshclam || return $?;

        msg_beginTask "Virus test...";
        
        curl https://secure.eicar.org/eicar.com.txt | clamscan -;
        if (( $? != 1 )); then
            return $?
        fi
    fi

    if ( contains "${TOINSTALL}" "ufw" ); then
        msg_beginTask "Configuring ufw...";
        systemctl enable ufw.service;
    fi
}

function install() {
    msg_beginTask "Installing packages..."; install_packages || return $?;

    if [ ${DISPLAYMANAGER} ]; then
        msg_beginTask "Configuring display manager(${DISPLAYMANAGER})...";    
        sudo systemctl enable ${DISPLAYMANAGER}.service || return $?;
    fi

    apps_setup || return $?;
    msg_beginTask "Removing cache files..."; rm -r /var/cache/pacman/pkg/* || return $?;

    msg_setupCompleted;
}

install;
