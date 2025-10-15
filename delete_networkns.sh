#!/bin/bash

# 0. be root
if [ "$(id -u)" != "0" ] ; then
  echo "retry as root" >&2
  exit 1
fi

# Remove the default route in the network namespace
ip netns exec mynetworkns ip route del default via 10.0.0.1

# Delete the masquerade rule from iptables
if type nft 2>/dev/null >&2 ; then
  H="$(nft --handle list ruleset | grep "10.0.0.0/24" | perl -pe 's/.* //g')"
  nft delete rule ip nat postrouting handle "$H"
else
  iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
fi

# Reset IP forwarding (if it was originally disabled)
# If you are unsure, it's safer to leave it as is or check its initial state.
sysctl -w net.ipv4.ip_forward=0

#remove ip addr from the host systemeth interface
ip addr del 10.0.0.1/24 dev systemeth

# Bring down and delete the systemeth veth interface
ip link set systemeth down
ip link del systemeth

# Delete the network namespace
ip netns del mynetworkns
