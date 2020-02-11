#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as sudo'
    exit
fi

source user/user_var.sh
source network/network_var.sh

echo
echo 'LOG: Install neutron package'
yum -y install openstack-neutron-linuxbridge ebtables ipset

echo 
echo 'LOG: Configure Common component'
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CONTROLLER_MANAGEMENT_IP
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER_MANAGEMENT_IP:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$CONTROLLER_MANAGEMENT_IP:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers $CONTROLLER_MANAGEMENT_IP:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

echo
echo 'LOG: Configure Linuxbridge plugin'
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$COMPUTE_MANAGEMENT_INT
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan false
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

echo
echo 'LOG: enable sysctl bridge'
# enable sysctl bridge
# net.bridge.bridge-nf-call-iptables
# net.bridge.bridge-nf-call-ip6tables
modprobe br_netfilter
sysctl -p /etc/sysctl.conf

echo
echo 'LOG: Configure the Compute service to use the Networking service'
crudini --set /etc/nova/nova.conf neutron url http://$CONTROLLER_MANAGEMENT_IP:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://$CONTROLLER_MANAGEMENT_IP:35357
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $NEUTRON_PASS

echo 
echo 'LOG: Restart compute service'
systemctl restart openstack-nova-compute.service

echo 
echo 'LOG: Start and enable linuxbridge agent'
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service

state=$(systemctl is-active neutron-linuxbridge-agent.service)

if [ $state = active ]; then
    echo
    echo '==========================================='
    echo '           INSTALL SUCCESSFULLY            '
    echo '==========================================='
else
    echo
    echo '==========================================='
    echo '              INSTALL FAILED               '
    echo '==========================================='
fi




