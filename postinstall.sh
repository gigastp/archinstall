#!/bin/bash

GPUDRIVER=nvidia;
DISPLAYMANAGER=lightdm;
DESKTOPENVIRONMANT=plasma;
SOUNDMANAGER=pulseaudio;
EDITOR=vi;

# Extra packages
TERMINALAPPS="clamav vim mc ranger ncdu htop neofetch";
BASICAPPS="xfce4-terminal firefox thunar file-roller clamtk xed lximage-qt kolourpaint xreader djview vlc audacious libreoffice-still gimp qbittorrent";
DEVELOPAPPS="gcc gdb make cmake git sqlite sqlitebrowser code qtcreator qt5-doc";
TOOLAPPS="cherrytree flameshot kdeconnect";
INTERNETAPPS="wireshark-qt telegram-desktop discord";
GAMEAPPS="steam wine dolphin-emu lutris";
OTHERAPPS="virtualbox";

TOINSTALL="${GPUDRIVER} ${DESKTOPENVIRONMANT} ${SOUNDMANAGER} ${TERMINALAPPS} ${BASICAPPS}\
 ${DEVELOPAPPS} ${TOOLAPPS} ${INTERNETAPPS} ${GAMEAPPS} ${OTHERAPPS}";

function install_packages() {
    if [ ${DISPLAYMANAGER} == "lightdm" ]; then
        TOINSTALL="${TOINSTALL} lightdm-gtk-greeter";
    fi

    if [ ${DISPLAYMANAGER} ]; then
        TOINSTALL="${TOINSTALL} ${DISPLAYMANAGER}";
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

    sudo ${EDITOR} /etc/pacman.conf && sudo pacman -Sy ${TOINSTALL};
    while (( $? )); do
        echo -n "Try again(press enter to start editing):"; read -s; echo;
        sudo ${EDITOR} /etc/pacman.conf && sudo pacman -Sy ${TOINSTALL};
    done
}

function install() {
    echo "== Installing packages..."; install_packages || return $?;

    if [ ${DISPLAYMANAGER} ]; then
        echo -e "== Configuring display manager(${DISPLAYMANAGER})...";    
        sudo systemctl enable ${DISPLAYMANAGER}.service || return $?;
    fi
    
    echo -e "== Configuring sound manager(${SOUNDMANAGER})...";    
    systemctl --user enable ${SOUNDMANAGER}.service || return $?;

    echo -e "== Removing cache files..."; sudo rm -r /var/cache/pacman/pkg/* || return $?;
    echo -e "\n< Setup complated >";
}

install
