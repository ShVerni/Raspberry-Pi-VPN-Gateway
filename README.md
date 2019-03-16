# Raspberry Pi VPN Gateway
Given the recent problems with mandating privacy for Internet users, it's important, now more than ever, that people consider their own methods for ensuring their privacy online. A Raspberry Pi can provide an excellent method for helping secure a home or office network against the collection of personal information. While this script is designed for a Raspberry Pi and the Private Internet Access service, it should be modifiable to work with any OpenVPN compatible service and on any Debian Jessie based system.

## About
This installer will help set up a Raspberry Pi to be a VPN gateway using the [Private Internet Access](https://www.privateinternetaccess.com/) service. By configuring a Raspberry Pi in this way, and pointing your router's DCHP at it, all traffic on your network can be funneled through an encrypted VPN tunnel for added privacy and security. This installer is based on the excellent work of superjamie found [here](https://gist.github.com/superjamie/ac55b6d2c080582a3e64).

__Warning:__ The scripts for this tool currently provide _no input validation_ for things like IP addresses; if you enter something incorrectly, abort the script and run it again, it should replace the bad settings. This tool is provided without warranty or guarantee that it will work correctly.

This is very much a work in progress, and I'm no Bash or Linux expert, so any feedback is much appreciated!

Before getting started, please be aware there are some tradeoffs to a VPN:
* There is overhead associated with the VPN on a Raspberry Pi, so your Internet connection could be slower. If having the absolute fastest connection is important, consider getting a [pre-configured router](https://www.flashrouters.com/vpn-types/privateinternetaccess).
* VPNs do not guarantee absolute privacy or security (see [this article](https://arstechnica.com/security/2016/06/aiming-for-anonymity-ars-assesses-the-state-of-vpns-in-2016/)).
* Sometimes services like Netflix or Hulu will block VPNs to prevent people circumventing region restrictions on content.
* There is some complexity added to your home networking setup, which can cause problems in rare cases and can make troubleshooting more challenging.

## Features
This tool comes with several features built-in, most of which can be optionally added while running the installer script:

### Up to Date
This script will download, compile, and install the most recent versions of OpenVPN and Monit to ensure best performance and security.

### Strong Encryption
This script will allow you to use the strongest encryption options [PIA offers](https://helpdesk.privateinternetaccess.com/hc/en-us/articles/218984968-What-is-the-difference-between-the-OpenVPN-config-files-on-your-website). Using stronger encryption will slow down the performance of the gateway, and therefore is not recommended unless you really want or need it. More information can be found [here](https://helpdesk.privateinternetaccess.com/hc/en-us/articles/231104368-What-Encryption-Can-I-Use). 

### Monit
The script will install and configure [Monit](https://mmonit.com/), which will monitor the VPN connection and ping Google.com every 10 seconds to ensure a good connection. If anything goes wrong, Monit will force a reboot by calling the `/home/pi/vpnfix.sh` script to try and solve the problem. When this happens, a timestamp will be written to the `/home/pi/vpnfix.log` file. Rebooting typically takes ~10 seconds to complete.

### Kill Switch
When enabled, the kill switch will block any traffic that does not go over the VPN tunnel. This means that if the VPN connection goes down, nothing on your network will be able to connect to the Internet unless you reset your default gateway to be your router (see the [Set Up Router](#set-up-router) section).

### VPN Bypass
When enabled, this will allow you to set up certain local IP addresses and (optionally) ports to bypass the VPN entirely. This is useful if you have devices that need open ports exposed to the Internet, or for things like a Roku that may be blocked by Netflix when using a VPN. To add bypass exceptions, see the [add_exception](#add_exception) section.

### Extra Utilities
All utility scripts are placed in the `/home/pi/` directory, and must be run as root.

#### add_exception
This utility will allow you to add an exception so that a specified local IP address and, optionally, port can bypass the VPN and access the Internet directly. When run, this script will ask for an IP address and an optional port and comment to create an exception for. It will also prompt you to select a protocol for the exception. The exception is added using the following iptables commands (omitting the port if not specified):
```bash
sudo iptables -t mangle -I PREROUTING 1 --source "[IP ADDR]" -p "[PROTOCOL]" -m "[PROTOCOL]" --dport "[PORT]" -m comment --comment "[COMMENT]" --j MARK --set-mark 1
sudo iptables -I FORWARD 1 --source "[IP ADDR]" -o eth0 -p "[PROTOCOL]" -m "[PROTOCOL]" --dport "[PORT]" -m comment --comment "[COMMENT]" --j ACCEPT
```
To undo an exception, you'll need to manually remove the created iptables rules. How to do so, and other iptables manipulations, is beyond the scope of this guide.

#### swap_endpoint
This utility will allow you to swap the VPN endpoint (VPN gateway) that you use. This will change the location or country that your traffic appears to come from. For best performance, you generally want to pick an endpoint near you, but there can be many reasons to use a different endpint. This script is mostly here as an example, and could be easily modified to work with a cron job to change your endpoint at regular intervals for added obfuscation.

#### update_OpenVPN
This utility will check to see if there is a newer version of OpenVPN available and, if so, will download, compile, and install it. During this process the VPN will be shutdown and, if you've enabled the [Kill Switch](#kill-switch), your Internet connection will be unavailable until this process is complete. This script can be enabled as a weekly cron job at a convenient time, along with other commands (an example of which is provided below) to keep the system up-to-date. Note that updates can be potentially breaking, but their importance often makes this a risk worth taking. Due to these complexities, creating cron jobs for automatic updating is not covered in this guide, however there are many [tutorials](https://help.ubuntu.com/community/CronHowto#Starting_to_Use_Cron) out there. You will need to use the root crontab and the `bash /home/pi/[script_name]` command.

Below is an example of a script that can be used to update Raspbian:
```bash
#!/bin/bash
#Check for root access.
if [ $(id -u) != "0" ]; then
        echo "You must be the superuser to run this script."
        exit 1
fi
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean
echo "$(date +"%F %T") Device updated" >> /home/pi/vpnfix.log
( sleep 2 ; reboot ) &
exit 0
```

## Requirements
This guide assumes you have some basic familiarity with Linux and the command line, if not, these [two](https://learn.adafruit.com/what-is-the-command-line/overview) [guides](http://linuxcommand.org/lc3_learning_the_shell.php) are a good introduction, and more general information can be found at the official [Raspberry Pi documentation](https://www.raspberrypi.org/documentation/). Again, if you'd rather not deal with the potential complexity of all this, consider a [pre-configured router](https://www.flashrouters.com/vpn-types/privateinternetaccess) or just using the [apps and programs](https://www.privateinternetaccess.com/pages/client-support/) provided by Private Internet Access.

### Materials
* A subscription to [Private Internet Access](https://www.privateinternetaccess.com/) (PIA).
* A [Raspberry Pi 3](https://www.amazon.com/Raspberry-Pi-RASPBERRYPI3-MODB-1GB-Model-Motherboard/dp/B01CD5VC92/).
* An [SD card](https://www.amazon.com/dp/B004UG41VY/) >= 8 GB.
* A [power supply](https://www.amazon.com/CanaKit-Raspberry-Supply-Adapter-Charger/dp/B00MARDJZ4/).
* An [Ethernet cable](https://www.amazon.com/AmazonBasics-RJ45-Cat-6-Ethernet-Patch-Cable-5-Feet-1-5-Meters/dp/B00N2VILDM/).
* Optionally, a [case with fan](https://www.amazon.com/Makerfire-Raspberry-Protective-Enclosure-Heatsink/dp/B019SIAGTO/), recommended for overclocking.

## Installation
### Set Up Raspbian
Download and install the Raspbian Jessie Lite image to your SD card using [this guide](https://www.raspberrypi.org/documentation/installation/installing-images/README.md), using NOOBS with Raspbian would also probably work. Once you finish writing the image to the SD card, you'll need to enable SSH. From the [Raspberry Pi](https://www.raspberrypi.org/documentation/remote-access/ssh/) documentation:
>For headless setup, SSH can be enabled by placing a file named 'ssh', without any extension, onto the boot partition of the SD card. When the Pi boots, it looks for the 'ssh' file. If it is found, SSH is enabled, and the file is deleted. The content of the file does not matter: it could contain text, or nothing at all.

You will need the Raspberry Pi to have an internet connection from here on out. The best way is to plug the Pi into your router via Ethernet. Connecting via WiFi or using the Pi as a WiFi router is beyond the scope of this guide.

Once the Raspberry Pi is booted and you've connected to the terminal via SSH (for help, see [this tool](https://learn.adafruit.com/the-adafruit-raspberry-pi-finder/overview/) or [this guide](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-6-using-ssh/)), run the following command:
```bash
sudo raspi-config
```
You'll be presented with a menu, choose the following options one at a time:
* Change User Password
* Network Options > N3 Network interface names > No (important to enable eth0 as ethernet network name)
* Boot Options > B1 Desktop / CLI > B2 Console Autologin
* Localisation Options (do each item in this submenu)
* Overclock > High (not available for the Pi 3, and only recommended if you have a case with a fan)
* Advanced Options > A1 Expand Filesystem
* Advanced Options > A3 Memory Split (set to 16)
* Finish (push tab key to get to this option)

You'll be prompted to reboot, do so.

### Run Installation Script
__Note:__ This script is designed to run on a clean installation of Raspbian or a device that has already had this script run on it, running it on a previously configured device could cause problems and overwrite the previous settings.

Things you'll need to know before running this script:
* The IP address of your current gateway (router), usually something like 192.168.0.1 or 192.168.1.1.
* The IP address you'd like your Raspberry Pi to use, can be anything that's not in use, like 192.168.1.254.
* Your username and password for the Private Internet Access service.

Once the Raspberry Pi has rebooted, and you've reconnected to it via SSH, run the following commands:
```bash
sudo apt-get install unzip -y
wget https://github.com/ShVerni/Raspberry-Pi-VPN-Gateway/archive/master.zip
unzip master.zip
cd Raspberry-Pi-VPN-Gateway-master
sudo chmod 744 InstallVPN.sh
sudo ./InstallVPN.sh
```
This will start the installation script which is divided into several sections. Follow the prompts and enter the appropriate information when asked. The script will take ~30-40 minutes to finish depending on your internet connection, most of which doesn't require your attention.

Once the script finishes, it will prompt you to reboot, once you do so you can check if the VPN is working by running this command:
```bash
ifconfig
```
If you see something like the following anywhere in the output, most importantly that tun0 exists, then your VPN is connected.
```bash
tun0      Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00
          inet addr:10.79.10.6  P-t-P:10.79.10.5  Mask:255.255.255.255
```
If there's a problem Monit will automatically reboot the Pi a minute or so after booting up, so to troubleshoot you'll need to disable Monit temporarily with this command (this needs to be done at each boot):
```bash
sudo monit stop all
```
Or, if that doesn't work, you can disable Monit entirely with the command:
```bash
sudo systemctl disable monit
```

### Set Up Router
Now that your Raspberry Pi is up and running, you need to point your router's DHCP configuration at it. Each router is different, but in general, look in your router's settings for the DHCP configuration and change it to match the following:
> Default gateway: [ip address of raspberry pi]
>
> Primary DNS: [ip address of raspberry pi]
>
> Secondary DNS: [ip address of raspberry pi]

Substitute the IP address you chose for your Raspberry Pi for [ip address of raspberry pi]. Save your settings and reboot your router, you may need to reboot your Raspberry Pi as well. If everything went well, you should be all done!
