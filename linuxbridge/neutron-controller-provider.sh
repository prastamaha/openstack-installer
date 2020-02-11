#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as sudo'
    exit
fi

source user/user_var.sh
source network/network_var.sh

echo 
echo 'LOG: Create neutron database'
mysql -u root -p$DBROOT_PASS -e "CREATE DATABASE neutron;"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRONDB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRONDB_PASS';"
mysql -u root -p$DBROOT_PASS -e "FLUSH PRIVILEGES;"

source ../admin_rc

echo 
echo 'LOG: Create neutron user'
openstack user create --domain default --password $NEUTRON_PASS neutron
openstack role add --project service --user neutron admin

echo
echo 'LOG: Create neutron service'
openstack service create --name neutron --description "OpenStack Networking" network

echo 
echo 'LOG: Create neutron api'
openstack endpoint create --region RegionOne network public http://$CONTROLLER_MANAGEMENT_IP:9696
openstack endpoint create --region RegionOne network internal http://$CONTROLLER_MANAGEMENT_IP:9696
openstack endpoint create --region RegionOne network admin http://$CONTROLLER_MANAGEMENT_IP:9696

echo
echo 'LOG: Install component'
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables

echo
echo 'LOG: Configure neutron component'
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$NEUTRONDB_PASS@$CONTROLLER_MANAGEMENT_IP/neutron

crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CONTROLLER_MANAGEMENT_IP
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

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
echo'LOG: Configure the Modular Layer 2 (ML2) plug-in'
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types 
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true

echo
echo'LOG: Configure the Linux bridge agent'
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$CONTROLLER_MANAGEMENT_INT
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan false
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true 
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

echo
echo 'LOG: enable sysctl bridge'
# enable sysctl bridge
# net.bridge.bridge-nf-call-iptables
# net.bridge.bridge-nf-call-ip6tables
modprobe br_netfilter
sysctl -p /etc/sysctl.conf

echo
echo 'LOG: Configure the DHCP agent'
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

echo 
echo 'LOG: Configure Metadata agent'
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host $CONTROLLER_MANAGEMENT_IP
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $METADATA_SECRET

echo
echo 'LOG: Configure Compute Service to Use Networking service'
crudini --set /etc/nova/nova.conf neutron url http://$CONTROLLER_MANAGEMENT_IP:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://$CONTROLLER_MANAGEMENT_IP:35357
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password $NEUTRON_PASS
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy true
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $METADATA_SECRET

echo
echo 'LOG: Create symbolic link ml2 service to plugin.ini'
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

echo
echo 'LOG: Populate database'
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

echo
echo 'LOG: Restart compute api'
systemctl restart openstack-nova-api.service

echo
echo 'LOG: Start and enable neutron service'
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service