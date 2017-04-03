#!/bin/bash
#Check for root access.
if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script."
    exit 1
fi

clear
echo "
~~~~~~~~~~~~~~~~~~~~~
This utility let's you swap out the endpoint, or
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
service openvpn stop
cp /home/pi/PIAopenvpn/ca.rsa.2048.crt /home/pi/PIAopenvpn/crl.rsa.2048.pem /etc/openvpn/
cp "$vpnregion" /etc/openvpn/PIAvpn.conf

#Modify configuration
sed -i 's/ca ca.rsa.2048.crt/ca \/etc\/openvpn\/ca.rsa.2048.crt/' /etc/openvpn/PIAvpn.conf
sed -i 's/auth-user-pass/auth-user-pass \/etc\/openvpn\/login/' /etc/openvpn/PIAvpn.conf
sed -i 's/crl-verify crl.rsa.2048.pem/crl-verify \/etc\/openvpn\/crl.rsa.2048.pem/' /etc/openvpn/PIAvpn.conf
echo "auth-nocache" | tee -a /etc/openvpn/PIAvpn.conf

clear

echo "
~~~~~~~~~~~~~~~~~~~~~~
Done! Do you want to reboot?
~~~~~~~~~~~~~~~~~~~~~~
"

select yn in "Yes" "No"; do
    case $yn in
        Yes) ( sleep 3 ; reboot ) &
			 echo "Restarting...";
		break;;
        No) exit 0;;
    esac
done
exit 0;