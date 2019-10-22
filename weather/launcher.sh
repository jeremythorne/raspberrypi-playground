#!/bin/bash

boot=$1

function do_boot {
    # loop checking for WiFi and exit if connected or after a minute
    # write status to console and inky phat display
    echo "hello..."
    ./inky_str.py "hello..."

    for i in 1 2 3 4 5 6; do
        sleep 10
        wifi=$(iwconfig 2>&1 | grep -oP '(?<=ESSID:).*')
        if [ ! -z "$wifi" ]; then
            echo "connected to $wifi"
            ./inky_str.py "WiFi: $wifi"
            exit 0
        else
            echo "no WiFi"
            ./inky_str.py "connecting..."
        fi
    done
    ./inky_str.py "No WiFi"
    exit 1
}

function do_weather {
    # fetch weather from met office and display on inky phat
    ./metoffice_weather_img.py inky
}

LOCKDIR=/tmp/launcher_lock

if mkdir $LOCKDIR; then
    trap "rm -r $LOCKDIR" EXIT
    if [ "$boot" = "boot" ]; then
        do_boot
    else
        do_weather
    fi
fi
