#!/bin/bash

# signal
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list

# regolith ppa
sudo add-apt-repository ppa:regolith-linux/release

packages="
regolith-desktop-standard
i3xrocks-weather
i3xrocks-memory
i3xrocks-volume
i3xrocks-battery
keepassxc
nextcloud-desktop
signal-desktop
gdebi-core
"


lst=''
for p in $packages; do
	lst="$lst $p"
done

sudo apt-get install $lst

# discord (depends on gdebi)
mkdir -p ~/Downloads
wget -O ~/Downloads/discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
sudo gdebi ~/Downloads/discord.deb

