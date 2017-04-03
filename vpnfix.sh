#!/bin/bash

echo "$(date +"%F %T") Forced reboot" >> /home/pi/vpnfix.log
( sleep 2 ; reboot ) &
exit 0
