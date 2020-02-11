#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as sudo'
    exit
fi

source user/user_var.sh
source network/network_var.sh

mysql -u root -p$DBROOT_PASS -e "CREATE DATABASE nova_api;"
mysql -u root -p$DBROOT_PASS -e "CREATE DATABASE nova;"
mysql -u root -p$DBROOT_PASS -e "CREATE DATABASE nova_cell0;"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVADB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$NOVADB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVADB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVADB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVADB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$NOVADB_PASS';"
mysql -u root -p$DBROOT_PASS -e "FLUSH PRIVILEGES;"

source ../admin_rc

echo 
echo 'LOG: Create nova user'
openstack user create --domain default --password $NOVA_PASS nova
openstack role add --project service --user nova admin

echo
echo 'LOG: Create nova service'
openstack service create --name nova --description "OpenStack Compute" compute

echo
echo 'LOG: Create nova api'
openstack endpoint create --region RegionOne compute public http://$CONTROLLER_MANAGEMENT_IP:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://$CONTROLLER_MANAGEMENT_IP:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://$CONTROLLER_MANAGEMENT_IP:8774/v2.1

echo 
echo 'LOG: Create plancement service user'
openstack user create --domain default --password $PLACEMENT_PASS placement
openstack role add --project service --user placement admin

echo
echo 'LOG: Create placement service'
openstack service create --name placement --description "Placement API" placement

echo
echo 'LOG: Create placement api'
openstack endpoint create --region RegionOne placement public http://$CONTROLLER_MANAGEMENT_IP:8778
openstack endpoint create --region RegionOne placement internal http://$CONTROLLER_MANAGEMENT_IP:8778
openstack endpoint create --region RegionOne placement admin http://$CONTROLLER_MANAGEMENT_IP:8778

echo
echo 'LOG: Install nova package'
yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler openstack-nova-placement-api -y

echo 
echo 'LOG: Configure nova'
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CONTROLLER_MANAGEMENT_IP
crudini --set /etc/nova/nova.conf DEFAULT my_ip $CONTROLLER_MANAGEMENT_IP
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf vnc enabled True
crudini --set /etc/nova/nova.conf vnc server_listen $CONTROLLER_MANAGEMENT_IP
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address $CONTROLLER_MANAGEMENT_IP

crudini --set /etc/nova/nova.conf glance api_servers http://$CONTROLLER_MANAGEMENT_IP:9292
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement os_region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://$CONTROLLER_MANAGEMENT_IP:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password $PLACEMENT_PASS

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$NOVADB_PASS@$CONTROLLER_MANAGEMENT_IP/nova_api
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$NOVADB_PASS@$CONTROLLER_MANAGEMENT_IP/nova

crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://$CONTROLLER_MANAGEMENT_IP:5000/v3
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers $CONTROLLER_MANAGEMENT_IP:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password $NOVA_PASS

echo 
echo 'LOG: Edit placement api'
cat >> /etc/httpd/conf.d/00-nova-placement-api.conf << EOF

<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>

EOF

echo
echo 'LOG: Restart httpd'
systemctl restart httpd

echo
echo 'LOG: Populate nova-api'
su -s /bin/sh -c "nova-manage api_db sync" nova

echo 
echo 'LOG: Populate cell0 database'
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

echo
echo 'LOG: Create cell1'
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

echo
echo 'LOG: Create nova database'
su -s /bin/sh -c "nova-manage db sync" nova

echo
echo 'LOG: Verify cell_v2 and cell1'
nova-manage cell_v2 list_cells

echo
echo 'LOG: Start and enable nova service'
systemctl enable openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

echo
echo '==========================================='
echo '           INSTALL SUCCESSFULLY            '
echo '==========================================='