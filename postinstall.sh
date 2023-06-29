#!/bin/bash

GPUDRIVER=nvidia;
DISPLAYMANAGER=lightdm;
DESKTOPENVIRONMANT=plasma;
SOUNDMANAGER=pulseaudio;
EDITOR=vi;

# Extra packages
TERMINALAPPS="bash clamav vim mc ranger ncdu htop neofetch";
BASICAPPS="xfce4-terminal firefox thunar file-roller clamtk xed 
 lximage-qt kolourpaint xreader djview vlc audacious libreoffice-still\
 gimp qbittorrent";
DEVELOPAPPS="gcc gdb make cmake git sqlite sqlitebrowser code\
 notepadqq qtcreator qt5-doc";
TOOLAPPS="cherrytree flameshot kdeconnect";
INTERNETAPPS="telegram-desktop discord";
GAMEAPPS="wine dolphin-emu lutris";
OTHERAPPS="virtualbox";

TOINSTALL="${GPUDRIVER} ${DISPLAYMANAGER}\
 ${DESKTOPENVIRONMANT} ${SOUNDMANAGER} ${TERMINALAPPS} ${BASICAPPS}\
 ${DEVELOPAPPS} ${TOOLAPPS} ${INTERNETAPPS} ${GAMEAPPS} ${OTHERAPPS}";

function install_packages() {
    if [ ${DISPLAYMANAGER} == "lightdm" ]; then
        TOINSTALL="${TOINSTALL} lightdm-gtk-greeter";
    fi
    
    if [ ${SOUNDMANAGER} == "pulseaudio" ]; then
        TOINSTALL="${TOINSTALL} pulseaudio-alsa";
    
        if [ ${DESKTOPENVIRONMANT} == "xfce4" ]; then
            TOINSTALL="${TOINSTALL} pavucontrol xfce4-pulseaudio-plugin";
        fi
    fi
    
    sudo pacman -Sy ${TOINSTALL};

}

function install() {
    install_packages || return $?; echo -e "Packages installed.\n";
    
    sudo systemctl enable ${DISPLAYMANAGER}.service || return $?; 
    echo "Display manager(${DISPLAYMANAGER}) configured.";
    
    systemctl --user enable ${SOUNDMANAGER}.service || return $?;
    echo "Sound manager(${SOUNDMANAGER}) configured.";
}

install
