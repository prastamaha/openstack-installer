#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as sudo'
    exit
fi

source user/user_var.sh
source network/network_var.sh

echo
echo 'LOG: Create glance database'
mysql -u root -p$DBROOT_PASS -e "CREATE DATABASE glance;"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCEDB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCEDB_PASS';"
mysql -u root -p$DBROOT_PASS -e "FLUSH PRIVILEGES;"

source ../admin_rc

echo
echo 'LOG: Create glance user'
openstack user create --domain default --password $GLANCE_PASS glance
openstack role add --project service --user glance admin

echo
echo 'LOG: Create glance service'
openstack service create --name glance --description "OpenStack Image" image

echo
echo 'LOG: Create glance api'
openstack endpoint create --region RegionOne image public http://$CONTROLLER_MANAGEMENT_IP:9292
openstack endpoint create --region RegionOne image internal http://$CONTROLLER_MANAGEMENT_IP:9292
openstack endpoint create --region RegionOne image admin http://$CONTROLLER_MANAGEMENT_IP:9292

echo 
echo 'LOG: Install Glance package'
yum install openstack-glance -y

echo
echo 'LOG: Configure glance'
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$GLANCEDB_PASS@$CONTROLLER_MANAGEMENT_IP/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$CONTROLLER_MANAGEMENT_IP:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$CONTROLLER_MANAGEMENT_IP:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers $CONTROLLER_MANAGEMENT_IP:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password $GLANCE_PASS
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store stores file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$GLANCEDB_PASS@$CONTROLLER_MANAGEMENT_IP/glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$CONTROLLER_MANAGEMENT_IP:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$CONTROLLER_MANAGEMENT_IP:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers $CONTROLLER_MANAGEMENT_IP:11211
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name Default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name Default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password $GLANCE_PASS
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

echo
echo 'LOG: Populate database'
su -s /bin/sh -c "glance-manage db_sync" glance

echo
echo 'LOG: Start and enable glance service'
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

echo
echo '==========================================='
echo '           INSTALL SUCCESSFULLY            '
echo '==========================================='