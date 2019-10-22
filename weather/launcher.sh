#!/bin/bash

boot=$1
no_inky=$2

function inky_str {
    echo $1
    if [ "$no_inky" != "no_inky" ]; then
        ./inky_str.py "$1"
    fi
}

function do_boot {
    # loop checking for WiFi and exit if connected or after a minute
    # write status to console and inky phat display
    inky_str "hello..."

    for i in 1 2 3 4 5 6; do
        /bin/sleep 10
        wifi=$(/sbin/iwconfig 2>&1 | /bin/grep -oP '(?<=ESSID:).*')
        if [ ! -z "$wifi" ]; then
            inky_str "WiFi: $wifi"
            exit 0
        else
            inky_str "connecting..."
        fi
    done
    inky_str "No WiFi"
    exit 1
}

function do_weather {
    # fetch weather from met office and display on inky phat
    ./metoffice_weather_img.py inky
}

LOCKDIR=/tmp/launcher_lock

if /bin/mkdir $LOCKDIR; then
    trap "/bin/rm -r $LOCKDIR" EXIT
    if [ "$boot" = "boot" ]; then
        do_boot
    else
        do_weather
    fi
fi
