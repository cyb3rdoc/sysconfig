#!/bin/bash

# Collect peer name and its wireguard IP from user
read -p "Enter Name for the Peer: " peer
[ -z $peer ] && echo -e "\nPeer Name Unavailable...Exiting." && exit
echo ""
read -p "Enter Wireguard IP for the Peer: " peerip
[ -z $peerip ] && echo -e "\nPeer IP Unavailable...Exiting." && exit

# Set basic parameters
USER=$(whoami)
WGDIR=/home/$USER/wireguard
PEERDIR=/home/$USER/wireguard/$peer
SERVERDIR=/etc/wireguard
SERVERIP="$(sudo cat $SERVERDIR/wg0.conf | grep "Address" | cut -d " " -f 3 | cut -d "/" -f 1)"
LISTENPORT="$(sudo cat $SERVERDIR/wg0.conf | grep "ListenPort" | cut -d " " -f 3)"
# If you are using a domain name or dynamic dns, update below value of WANIP
WANIP="$(wget -q -O - https://ifconfig.io/ip)"
#WANIP="mydomain.example.com"

# Check for peer directory or generate
umask 077
[ -d $WGDIR ] || mkdir $WGDIR
[ -d $PEERDIR ] || mkdir $PEERDIR

# Generate peer keys
wg genkey > $PEERDIR/$peer.key
wg pubkey < $PEERDIR/$peer.key > $PEERDIR/$peer.pub
wg genpsk > $PEERDIR/$peer.psk

# Generate peer configuration file
echo "\
[Interface]
Address = $peerip/32
PrivateKey = $(cat $PEERDIR/$peer.key)
DNS = $SERVERIP

[Peer]
Endpoint = $WANIP:$LISTENPORT
AllowedIPs = 0.0.0.0/0
PublicKey = $(sudo cat $SERVERDIR/server.pub)
PresharedKey = $(cat $PEERDIR/$peer.psk)" > $PEERDIR/$peer.conf

# Shutdown wireguard server to save new configuration
echo -e "\nShutting down wireguard server..."
sudo wg-quick down wg0

# Backup current server configuration
echo -e "\nBacking up current server configuration..."
sudo cp $SERVERDIR/wg0.conf $SERVERDIR/wg0.conf.bak

# Update server configuration
echo "\

[Peer]
AllowedIPs = $peerip/32
PublicKey = $(cat $PEERDIR/$peer.pub)
PresharedKey = $(cat $PEERDIR/$peer.psk)" | sudo tee -a $SERVERDIR/wg0.conf > /dev/null

echo -e "\nWireguard profile for $peer generated."
echo -e "\nRestarting wireguard server..."
sudo wg-quick up wg0
echo ""

# Generate QR code of peer.conf file
if ! [ -x "$(command -v qrencode)" ]; then
    echo "qrencode is not installed. QR code generation skipped." >&2
    exit
fi

read -p "Do you want to generate peer configuration QR code? (y/n): " yn
case $yn in
    [yY]* ) qrencode -t ansiutf8 -r "$PEERDIR/$peer.conf";
        exit;;
    [nN]* ) echo QR code generation cancelled...Exiting.;
        exit;;
    * ) echo Invalid response...Exiting.;
        exit;;
esac
