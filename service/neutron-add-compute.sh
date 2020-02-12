#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

echo 'WARNING: this script is run when the neutron service on the compute node is running, make sure you have installed the neutron service on the compute node before running this script'

read -p 'Are you sure to continue? [Y/n]' run

if [ "$run" = "Y" ]; then
    
    source ../admin_rc
    
    echo
    echo "LOG: Populate neutron database"
    su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

    echo
    echo 'LOG: Restart Nova api'
    systemctl restart openstack-nova-api.service

    echo
    echo 'LOG: Restart Neutron service'
    systemctl start neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service neutron-l3-agent.service

    echo
    echo "LOG: Run command 'openstack network agent list'"
    openstack network agent list
    
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
