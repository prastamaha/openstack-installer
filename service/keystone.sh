#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

source network/network_var.sh
source user/user_var.sh

echo
echo "LOG: create keystone database"
mysql -u root -p$DBROOT_PASS -e "CREATE DATABASE keystone;"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONEDB_PASS';"
mysql -u root -p$DBROOT_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONEDB_PASS';"
mysql -u root -p$DBROOT_PASS -e "FLUSH PRIVILEGES;"

echo
echo "LOG: install package"
yum install openstack-keystone httpd mod_wsgi -y

echo
echo "LOG: edit configuration"
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:$KEYSTONEDB_PASS@$CONTROLLER_MANAGEMENT_IP/keystone
crudini --set /etc/keystone/keystone.conf token provider fernet

echo
echo "LOG: populate database"
su -s /bin/sh -c "keystone-manage db_sync" keystone

echo
echo "LOG: init fernet key"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

echo
echo "LOG: bootstrap keystone"
keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://$CONTROLLER_MANAGEMENT_IP:5000/v3/ \
  --bootstrap-internal-url http://$CONTROLLER_MANAGEMENT_IP:5000/v3/ \
  --bootstrap-public-url http://$CONTROLLER_MANAGEMENT_IP:5000/v3/ \
  --bootstrap-region-id RegionOne

echo
echo "LOG: configure httpd"
cat >> /etc/httpd/conf/httpd.conf << EOF
ServerName controller
EOF

echo
echo "LOG: create link"
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

echo
echo "LOG: start"
systemctl enable httpd.service
systemctl start httpd.service

echo
echo "LOG: create environment file"
cat > ../admin_rc << EOF
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF
source ../admin_rc

echo
echo "LOG: verify"
openstack --os-auth-url http://controller:35357/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue

echo
echo "LOG: create service project"
openstack project create --domain default --description "Service Project" service

echo
echo '==========================================='
echo '           INSTALL SUCCESSFULLY            '
echo '==========================================='