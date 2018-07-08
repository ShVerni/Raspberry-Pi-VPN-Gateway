#!/bin/bash

#Check for root access.
if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script."
    exit 1
fi

clear
echo "
~~~~~~~~~~~~~~~~~~~~~
This utility lets you add an exception to the VPN.
The device at the given IP address and, optionally, port
will be allowed to bypass the VPN connection.
~~~~~~~~~~~~~~~~~~~~~
"

#Get values
read -p 'IP Address: ' ipaddr
read -p 'Port [optional]: ' port
read -p 'Comment [optional]: ' comment

PS3='Select a protocol: '
select prot in "tcp" "udp" ; do
	if (( REPLY > 0 && REPLY <= 4 )); then
        break
    else
        echo "Invalid option. Try another one."
    fi
done

if [ -n "$port" ]; then
	sudo iptables -t mangle -I PREROUTING 1 --source "$ipaddr" -p "$prot" -m "$prot" --dport "$port" -m comment --comment "$comment" --j MARK --set-mark 1
	sudo iptables -I FORWARD 1 --source "$ipaddr" -o eth0 -p "$prot" -m "$prot" --dport "$port" -m comment --comment "$comment" --j ACCEPT
else
	sudo iptables -t mangle -I PREROUTING 1 --source "$ipaddr" -p "$prot" -m "$prot" -m comment --comment "$comment" --j MARK --set-mark 1
	sudo iptables -I FORWARD 1 --source "$ipaddr" -o eth0 -p "$prot" -m "$prot" -m comment --comment "$comment" --j ACCEPT
fi
netfilter-persistent save

echo "
~~~~~~~~~~~~~~~~~~~~~
Done!
~~~~~~~~~~~~~~~~~~~~~
"
exit 0;
