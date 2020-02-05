#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

source ../network/network_var.sh

echo
echo "LOG: install package"
yum install openstack-dashboard -y

echo
echo "LOG: configure"
sed -i -e 's/OPENSTACK_HOST.*=.*/OPENSTACK_HOST = "$CONTROLLER_PROVIDER_IP"/' /etc/openstack_dashboard/local_settings
sed -i -e "s/ALLOWED_HOSTS.*=.*/ALLOWED_HOSTS = ['*']/" /etc/openstack_dashboard/local_settings
cat >> /etc/openstack_dashboard/local_settings << EOF
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
EOF
