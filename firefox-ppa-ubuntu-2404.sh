#!/bin/bash

sudo snap remove firefox
if [ $? -ne 0 ]; then exit 1; fi

sudo apt remove firefox
if [ $? -ne 0 ]; then exit 1; fi

sudo add-apt-repository ppa:mozillateam/ppa
if [ $? -ne 0 ]; then exit 1; fi

sudo tee /etc/apt/preferences.d/mozilla <<EOF
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
EOF

sudo apt update
if [ $? -ne 0 ]; then exit 1; fi

sudo apt install firefox
if [ $? -ne 0 ]; then exit 1; fi

