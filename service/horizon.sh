#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

source network/network_var.sh

echo
echo "LOG: install package"
yum install openstack-dashboard -y

echo
echo "LOG: configure"
sed -i -e "s/OPENSTACK_HOST.*=.*/OPENSTACK_HOST = '$CONTROLLER_MANAGEMENT_IP'/" /etc/openstack-dashboard/local_settings
sed -i -e "s/ALLOWED_HOSTS.*=.*/ALLOWED_HOSTS = ['*']/" /etc/openstack-dashboard/local_settings
cat >> /etc/openstack-dashboard/local_settings << EOF
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
EOF
#sed -i -e 's/#* *#CACHES .*= {.*/CACHES = {/' /etc/openstack-dashboard/local_settings
#sed -i -e "s/#*.*'default'.*: {.*/    'default': {/" /etc/openstack-dashboard/local_settings
sed -i -e "167s/#*.*'BACKEND'.*:.*/        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',/" /etc/openstack-dashboard/local_settings
sed -i -e "167 a 'LOCATION': '$CONTROLLER_MANAGEMENT_IP:11211'," /etc/openstack-dashboard/local_settings
#sed -i -e "s/#*.*'LOCATION'.*:.*/        'LOCATION': '$CONTROLLER_MANAGEMENT_IP:11211',}}/" /etc/openstack-dashboard/local_settings
sed -i -e "168s/'LOCATION':.*/        'LOCATION': '$CONTROLLER_MANAGEMENT_IP:11211',/" /etc/openstack-dashboard/local_settings
sed -i -e "169s/#*.*}.*,/    }/" /etc/openstack-dashboard/local_settings
#sed -i -e "s/#}/}/" /etc/openstack-dashboard/local_settings
sed -i -e 's/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"/' /etc/openstack-dashboard/local_settings
sed -i -e "s/#*.*OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT.*=.*/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/" /etc/openstack-dashboard/local_settings
cat >> /etc/openstack-dashboard/local_settings << EOF
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
EOF
cat >> /etc/httpd/conf.d/openstack-dashboard.conf << EOF
WSGIApplicationGroup %{GLOBAL}
EOF
systemctl restart httpd.service memcached.service