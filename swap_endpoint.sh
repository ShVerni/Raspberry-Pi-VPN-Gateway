#!/bin/bash
#Check for root access.
if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script."
    exit 1
fi

clear
echo "
~~~~~~~~~~~~~~~~~~~~~
This utility lets you swap out the endpoint, or
VPN gateway, that you conenct through.
~~~~~~~~~~~~~~~~~~~~~
Press any key to continue" 
read -n 1 -s

files=$(find /home/pi/PIAopenvpn/ -maxdepth 1 -type f -regex ".*ovpn")
readarray -t options <<<"$files"
clear
echo "Please select an endpoint number to swap to:"
PS3='Select an endpoint: '
select vpnregion in "${options[@]}" ; do
    if (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        break
    else
        echo "Invalid option. Try another one."
    fi
done
systemctl stop monit.service
systemctl stop openvpn

if grep -Fxq "cipher aes-128-cbc" /etc/openvpn/PIAvpn.conf
then
	STRONG=0
else
	STRONG=1
fi

if [ "$STRONG" -eq 0 ]; then
	cp /home/pi/PIAopenvpn/ca.rsa.2048.crt /home/pi/PIAopenvpn/crl.rsa.2048.pem /etc/openvpn/
else
	cp /home/pi/PIAopenvpn/ca.rsa.4096.crt /home/pi/PIAopenvpn/crl.rsa.4096.pem /etc/openvpn/
fi
cp "$vpnregion" /etc/openvpn/PIAvpn.conf

#Modify configuration
if [ "$STRONG" -eq 0 ]; then
	sed -i 's/ca ca.rsa.2048.crt/ca \/etc\/openvpn\/ca.rsa.2048.crt/' /etc/openvpn/PIAvpn.conf
	sed -i 's/crl-verify crl.rsa.2048.pem/crl-verify \/etc\/openvpn\/crl.rsa.2048.pem/' /etc/openvpn/PIAvpn.conf
else
	sed -i 's/ca ca.rsa.4096.crt/ca \/etc\/openvpn\/ca.rsa.4096.crt/' /etc/openvpn/PIAvpn.conf
	sed -i 's/crl-verify crl.rsa.4096.pem/crl-verify \/etc\/openvpn\/crl.rsa.4096.pem/' /etc/openvpn/PIAvpn.conf
fi

sed -i 's/auth-user-pass/auth-user-pass \/etc\/openvpn\/login/' /etc/openvpn/PIAvpn.conf
echo "auth-nocache" | tee -a /etc/openvpn/PIAvpn.conf
echo -e "script-security 2\nup /etc/openvpn/update-resolv-conf\ndown /etc/openvpn/update-resolv-conf" | tee -a /etc/openvpn/PIAvpn.conf

#Restart OpenVPN
systemctl start openvpn
systemctl start monit.service

echo "
~~~~~~~~~~~~~~~~~~~~~~
Done!
~~~~~~~~~~~~~~~~~~~~~~
"
exit 0
