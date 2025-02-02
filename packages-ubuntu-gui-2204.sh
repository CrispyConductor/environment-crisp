#!/bin/bash

# signal
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list

# regolith ppa
#wget -qO - https://regolith-desktop.org/regolith.key | gpg --dearmor | sudo tee /usr/share/keyrings/regolith-archive-keyring.gpg > /dev/null
#echo deb "[arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] https://regolith-desktop.org/release-ubuntu-jammy-amd64 jammy main" |sudo tee /etc/apt/sources.list.d/regolith.list

sudo apt update

packages="
keepassxc
nextcloud-desktop
signal-desktop
gdebi-core
xclip
python3-tk
"

#packages="
#regolith-desktop
#i3xrocks-weather
#i3xrocks-memory
#i3xrocks-volume
#i3xrocks-battery
#keepassxc
#nextcloud-desktop
#signal-desktop
#gdebi-core
#xclip
#python3-tk
#"


lst=''
for p in $packages; do
	lst="$lst $p"
done

sudo apt-get install $lst

# discord (depends on gdebi)
mkdir -p ~/Downloads
wget -O ~/Downloads/discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
sudo gdebi ~/Downloads/discord.deb

