#!/bin/bash

######################################################################
# Title   : Wireguard Peer Profile Generation Script
# By      : cyb3rdoc
# License : MIT
######################################################################

# Collect peer name and its wireguard IP from user
read -p "\nEnter Name for the Peer: " PEER
[[ -z ${PEER} ]] && echo -e "\nPeer Name Unavailable...Exiting." && exit
read -p "\nEnter Wireguard IP for the Peer: " PEERIP
[[ -z ${PEERIP} ]] && echo -e "\nPeer IP Unavailable...Exiting." && exit

# Set basic parameters
USER=$(whoami)
WGDIR="/home/${USER}/wireguard"
PEERDIR="/home/${USER}/wireguard/${PEER}"
SERVERDIR="/etc/wireguard"
SERVERIP="$(sudo cat ${SERVERDIR}/wg0.conf | grep "Address" | cut -d " " -f 3 | cut -d "/" -f 1)"
LISTENPORT="$(sudo cat ${SERVERDIR}/wg0.conf | grep "ListenPort" | cut -d " " -f 3)"

# Identify server domain or public IP
VALIDATE="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"
read -p "\nIs your server accessible via a domain? (y/N): " DOMAINIP
case ${DOMAINIP} in
    [yY]* ) read -p "\nEnter your server domain (myserver.example.com): " WANIP
            if [[ -z ${WANIP} ]]; then
                echo -e "\nDomain Name Unavailable...Using Public IP."
                WANIP="$(wget -q -O - https://ifconfig.io/ip)"
            else
                if [[ ${WANIP} =~ ${VALIDATE} ]]; then
                    echo -e "\nValid domain name. Using ${WANIP} to access Wireguard Server."
                else
                    echo -e "\nInvalid Domain Name...Using Public IP."
                    WANIP="$(wget -q -O - https://ifconfig.io/ip)"
                fi
            fi
        ;;
    [nN]* ) echo -e "\nDomain Name Unavailable...Using Public IP."
            WANIP="$(wget -q -O - https://ifconfig.io/ip)"
        ;;
    * ) echo "Invalid response...Using server Public IP."
            WANIP="$(wget -q -O - https://ifconfig.io/ip)"
        ;;
esac

# Check for peer directory or generate
umask 077
[[ -d ${WGDIR} ]] || mkdir ${WGDIR}
[[ -d ${PEERDIR} ]] || mkdir ${PEERDIR}

# Generate peer keys
wg genkey > ${PEERDIR}/${PEER}.key
wg pubkey < ${PEERDIR}/${PEER}.key > ${PEERDIR}/${PEER}.pub
wg genpsk > ${PEERDIR}/${PEER}.psk

# Generate peer configuration file
echo "\
[Interface]
Address = ${PEERIP}/32
PrivateKey = $(cat ${PEERDIR}/${PEER}.key)
DNS = ${SERVERIP}

[Peer]
Endpoint = ${WANIP}:${LISTENPORT}
AllowedIPs = 0.0.0.0/0
PublicKey = $(sudo cat ${SERVERDIR}/server.pub)
PresharedKey = $(cat ${PEERDIR}/${PEER}.psk)" > ${PEERDIR}/${PEER}.conf

# Shutdown wireguard server to save new configuration
echo -e "\nShutting down wireguard server..."
sudo wg-quick down wg0

# Backup current server configuration
echo -e "\nBacking up current server configuration..."
sudo cp ${SERVERDIR}/wg0.conf ${SERVERDIR}/wg0.conf.bak

# Update server configuration
echo "\

[Peer]
AllowedIPs = ${PEERIP}/32
PublicKey = $(cat ${PEERDIR}/${PEER}.pub)
PresharedKey = $(cat ${PEERDIR}/${PEER}.psk)" | sudo tee -a ${SERVERDIR}/wg0.conf > /dev/null

echo -e "\nWireguard profile for ${PEER} generated."
echo -e "\nRestarting wireguard server..."
sudo wg-quick up wg0

# Generate QR code of peer.conf file
if ! [[ -x "$(command -v qrencode)" ]]; then
    echo -e "\nqrencode is not installed. QR code generation skipped." >&2
    echo -e "\nWireguard Peer Profile Generation Completed."
    exit
fi

read -p "Do you want to generate peer configuration QR code? (y/n): " YN
case ${YN} in
    [yY]* ) qrencode -t ansiutf8 -r "${PEERDIR}/${PEER}.conf"
        ;;
    [nN]* ) echo "QR code generation cancelled...Exiting."
        ;;
    * ) echo "Invalid response...Exiting."
        ;;
esac

echo -e "/nWireguard Peer Profile Generation Completed."
