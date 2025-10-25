#!/bin/bash
######################################################################
# Title   : Static IPv6 Prefix Auto-Updater
# By      : cyb3rdoc
# License : MIT
######################################################################
# This script monitors IPv6 prefix changes for eth0 and updates the 
# "static ip6_address" entry in /etc/dhcpcd.conf.
#
# Features:
# - Monitors eth0 for IPv6 prefix changes.
# - Updates /etc/dhcpcd.conf only if the prefix changes.
# - Prevents unnecessary restarts by restarting dhcpcd only when needed.
# - Stores the last known prefix in /etc/ipv6prefix to track changes across reboots.
######################################################################
# Configuration
CONFIG_FILE="/etc/dhcpcd.conf"
PREFIX_FILE="/etc/ipv6prefix"
INTERFACE="eth0"
STATIC_SUFFIX="::1001"  # Define the static suffix for interface

echo "Checking IPv6 prefix for $INTERFACE..."

# Get the current IPv6 global prefix (excluding static and deprecated addresses)
NEW_PREFIX=$(ip -6 addr show "$INTERFACE" \
    | grep "global" | grep "dynamic" | grep -v "deprecated" \
    | awk '{print $2}' | cut -d'/' -f1 | cut -d':' -f1-4 | head -n1)

# Check if an IPv6 prefix was found
if [[ -z "$NEW_PREFIX" ]]; then
    echo "No IPv6 prefix detected for $INTERFACE. Exiting..."
    exit 0
fi

# Load the previous prefix
if [[ -f "$PREFIX_FILE" ]]; then
    OLD_PREFIX=$(cat "$PREFIX_FILE")
else
    OLD_PREFIX=""
fi

# New static IPv6 address
NEW_IPV6="$NEW_PREFIX$STATIC_SUFFIX/64"

# Check if IPv6 prefix changed
if [[ "$NEW_PREFIX" != "$OLD_PREFIX" ]]; then
    echo "IPv6 prefix changed from $OLD_PREFIX to $NEW_PREFIX"

    # Update dhcpcd.conf
    sudo awk -v iface="$INTERFACE" -v new_ipv6="$NEW_IPV6" '
        BEGIN { inside_iface=0 }
        # Detect an "interface ..." line. Use field comparison to be robust.
        /^interface/ {
            # reset inside_iface then set if this line is the interface we care about
            inside_iface = ($1 == "interface" && $2 == iface)
            print
            next
        }
        # If we are inside the matching interface stanza, replace static ip6_address lines
        inside_iface && /^[[:space:]]*static[[:space:]]+ip6_address=/ {
            sub(/static[[:space:]]+ip6_address=.*/, "static ip6_address=" new_ipv6)
            print
            next
        }
        { print }
    ' "$CONFIG_FILE" | sudo tee "$CONFIG_FILE.tmp" > /dev/null && sudo mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    # Save the new prefix
    sudo echo "$NEW_PREFIX" > "$PREFIX_FILE"

    # Restart dhcpcd
    echo "Restarting dhcpcd service..."
    sudo systemctl restart dhcpcd
    echo "IPv6 prefix updated for $INTERFACE."
else
    echo "IPv6 prefix unchanged. No update needed."
fi
