#!/bin/bash

# 0. be root
if [ "$(id -u)" != "0" ] ; then
  echo "retry as root" >&2
  exit 1
fi

if ! type debootstrap 2>/dev/null >&2 ; then
  apt install debootstrap
fi

# Container Setup Using debootstrap
mkdir containers
debootstrap --variant=minbase stable ./containers http://deb.debian.org/debian/

# Setup Network Namespace
# Copy or create your server.js file
# Start the network namespace
bash create_network.sh

# Enter the Container Namespace
unshare --mount --pid --uts --net --cgroup --fork /bin/bash

ip netns exec mynetworkns chroot ./containers /bin/bash
# Fix DNS and Hostname
# Try ping (it won’t work yet)
# ping -c 3 8.8.8.8

# Add DNS resolver
echo 'nameserver 8.8.8.8' > /etc/resolv.conf

# Set container hostname
hostname cloudmash-container
Install Utilities Inside the Container
apt-get install iputils-ping procps nano nodejs iproute2 -y

# Mount Required Filesystems
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t tmpfs tmpfs /tmp

# Setup Cgroups
# Go to HOST system (your main system,outside container), this setting you have to do in host system
cd /sys/fs/cgroup
mkdir mycgroup
echo "+cpu" > /sys/fs/cgroup/cgroup.subtree_control
echo "50000 100000" > /sys/fs/cgroup/mycgroup/cpu.max
echo "500000000" > /sys/fs/cgroup/mycgroup/memory.max

#Get process id of 2nd networkns process , because first is sudo process and last one is grep itself
PID="$(pgrep "mynetworkns" | tail -n 1)"

# Add process ID of network namespace process here
echo "$PID" >> /sys/fs/cgroup/mycgroup/cgroup.procs

# verify whether cgroup changed to mycgroup for mynetworkns process
# this should show something like 0::mycgroup
# cat "/proc/$PID/cgroup"

