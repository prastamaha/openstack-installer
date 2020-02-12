#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as sudo'
    exit
fi

source user/user_var.sh
source network/network_var.sh

echo
echo 'LOG: Install component'
yum install openstack-neutron-openvswitch ebtables ipset -y

echo
echo 'LOG: Configure component'
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CONTROLLER_MANAGEMENT_IP
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$CONTROLLER_MANAGEMENT_IP:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$CONTROLLER_MANAGEMENT_IP:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers $CONTROLLER_MANAGEMENT_IP:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS

crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_domain_name Default
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron user_domain_name Default
crudini --set /etc/nova/nova.conf neutron auth_url http://$CONTROLLER_MANAGEMENT_IP:35357
crudini --set /etc/nova/nova.conf neutron url http://$CONTROLLER_MANAGEMENT_IP:9696
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $NEUTRON_PASS

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings external:br-external
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $COMPUTE_MANAGEMENT_IP
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True

echo
echo 'LOG: Create br-external interface for provider network'
systemctl start neutron-openvswitch-agent
ovs-vsctl add-br br-external
ovs-vsctl add-port br-external $COMPUTE_PROVIDER_INT
#ovs-vsctl show

echo
echo 'LOG: Restart nova api'
systemctl restart openstack-nova-compute.service

echo
echo 'LOG: Start and enable openvswitch agent'
systemctl enable neutron-openvswitch-agent.service
systemctl start neutron-openvswitch-agent.service

echo
echo '==========================================='
echo '           INSTALL SUCCESSFULLY            '
echo '==========================================='
