#!/bin/bash
#Check for root access.
if [ $(id -u) != "0" ]; then
	echo "You must be the superuser to run this script."
	exit 1
fi
NEW_VERSION=$(wget -qO - https://build.openvpn.net/downloads/releases/latest/LATEST.txt | head -1 | egrep -o '([0-9]\.?[0-9]\.?[0-9]\.?[0-9]?)')
OLD_VERSION=$(/usr/sbin/openvpn --version | head -1 | egrep -o '([0-9]\.?[0-9]\.?[0-9]\.?[0-9]?) ' | tr -d '[:space:]')
if [ "$NEW_VERSION" != "$OLD_VERSION" ]; then
	wget https://build.openvpn.net/downloads/releases/latest/openvpn-latest-stable.tar.gz
	systemctl stop monit.service
	systemctl stop openvpn
	mkdir openvpn-new
	gzip -dc openvpn-latest-stable.tar.gz | tar -xf - -C openvpn-new --strip-components=1
	cd openvpn-new/
	./configure --prefix=/usr
	make
	make install
	cd ..
	rm openvpn-latest-stable.tar.gz
	rm -R openvpn-new
	systemctl start openvpn
	systemctl start monit.service
	echo "$(date +"%F %T") OpenVPN Updated from $OLD_VERSION to $NEW_VERSION" >> /home/pi/vpnfix.log
fi
exit 0
