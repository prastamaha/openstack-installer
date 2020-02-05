#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

echo 'WARNING: this script is run when the nova service on the compute node is running, make sure you have installed the nova service on the controller node before running this script'

run='Y'
read -p 'Are you sure to continue? [Y/n]' $run

if [ $run -eq 'Y' ]; then
    echo
    echo "LOG: Add compute node to cell database Run this on controller node"
    source ../admin_rc
    openstack compute service list --service nova-compute
    su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
elif [ $run = 'n' ]; then
    echo 'Exited from Nova add compute'
    exit
else
    echo 'Command not found'
    exit
fi


