#!/bin/bash

# Check for root privileges
if [[ "$EUID" = 0 ]]; then
    echo "Root privileges available"
else
    sudo -k # make sure to ask for password on next sudo
    if sudo true; then
        echo "Correct password"
    else
        echo "Wrong password"
        exit 1
    fi
fi

# Collect required information from user
read -p "Enter Wireguard Server IP e.g.10.X.X.X: " serverip
[ -z $serverip ] && echo -e "\nServer IP Unavailable...Exiting." && exit
echo ""
read -p "Enter Wireguard Server Listening Port e.g. 54321: " listenport
[ -z $listenport ] && echo -e "\nServer Listening Port Unavailable...Exiting." && exit

SERVERDIR=/etc/wireguard

# Set umask for new files
umask 077

# Generate server keys
wg genkey > $SERVERDIR/server.key
wg pubkey < $SERVERDIR/server.key > $SERVERDIR/server.pub

# Generate server configuration file
echo "\
[Interface]
Address = $serverip/24
ListenPort = $listenport
SaveConfig = True
PrivateKey = $(sudo cat $SERVERDIR/server.key)" > $SERVERDIR/wg0.conf

# Change your network interface from eth0 to appropriate as per network setup
read -p "Do you want to use Wireguard as VPN to access internet? (y/n): " yn
case $yn in
    [yY]*)      read -p "Enter Interface Name with Internet Access e.g. eth0, wlan0: " vpnif
                if [ -z $vpnif ]; then
                    echo -e "\nInterface name unavailable. Internet access via wireguard cancelled."
                else
                    echo "Updating iptables rules..."
                    echo "PostUp = iptables -I FORWARD 1 -i wg0 -j ACCEPT; iptables -t nat -I POSTROUTING 1 -o $vpnif -j MASQUERADE" >> $SERVERDIR/wg0.conf
                    echo "PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $vpnif -j MASQUERADE" >> $SERVERDIR/wg0.conf
                    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
                    sysctl -p
                fi
                ;;
    [nN]*)      echo "Internet access via wireguard cancelled."
                ;;
    *)          echo "Invalid response. Internet access via wireguard cancelled."
                ;;
esac

# Start wireguard server
echo -e "\nStarting wireguard server..."
wg-quick up wg0

# Enable server start at boot
echo -e "\nEnabling server start at boot..."
systemctl enable wg-quick@wg0

echo -e "\nWireguard server setup completed."
