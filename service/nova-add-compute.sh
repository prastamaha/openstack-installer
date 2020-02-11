#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

echo 'WARNING: this script is run when the nova service on the compute node is running, make sure you have installed the nova service on the compute node before running this script'

read -p 'Are you sure to continue? [Y/n]' run

if [ "$run" = "Y" ]; then
    echo
    echo "LOG: Add compute node to cell database Run this on controller node"
    source ../admin_rc
    openstack compute service list --service nova-compute
    su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

    echo
    echo "LOG: Run command 'openstack compute service list'"
    openstack compute service list
elif [ "$run" = "n" ]; then
    echo 'Exited from Nova add compute'
    exit
else
    echo 'Command not found'
    exit
fi

#echo
#echo '==========================================='
#echo '           INSTALL SUCCESSFULLY            '
#echo '==========================================='