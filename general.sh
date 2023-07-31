#!/bin/bash

FILESYSTEM=btrfs;
EDITOR=vi;

function contains() {
    local ARR=$1;
    for word in ${ARR[@]}; do
        if [ $word == "$2" ]; then
            return 0;
        fi
    done

    return 1;
}

function msg_beginTask() {
    echo -e "== ${*}";
}

function msg_setupCompleted() {
    echo -e "\n< Setup completed >";
}