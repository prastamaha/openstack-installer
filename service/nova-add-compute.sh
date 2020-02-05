#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

echo
echo "LOG: Add compute node to cell database Run this on controller node"
source ../admin_rc
openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova