#!/bin/bash

# 0. be root
if [ "$(id -u)" != "0" ] ; then
  echo "retry as root" >&2
  exit 1
fi

# Revert Cgroup Changes
# On your host(outside container)
echo "-cpu" > /sys/fs/cgroup/cgroup.subtree_control
rmdir /sys/fs/cgroup/mycgroup

# Stop Network Namespace
bash delete_networkns.sh
