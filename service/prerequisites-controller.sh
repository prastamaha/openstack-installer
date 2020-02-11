#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as sudo'
    exit
fi

source network/network_var.sh
source user/user_var.sh

echo 
echo 'LOG: Update Repository'
yum -y update
yum -y install centos-release-openstack-queens epel-release
yum repolist
yum -y update

echo
echo 'LOG: Install Utility Package'
yum -y install vim nano wget screen crudini htop

echo
echo 'LOG: Configure NTP'
yum -y install chrony
systemctl enable chronyd.service
systemctl restart chronyd.service
#systemctl status chronyd.service

echo
echo 'LOG: Disable Firewall and Install openstack Selinux'
yum -y install openstack-selinux
systemctl stop firewalld.service
systemctl disable firewalld.service
#systemctl status firewalld.service

echo 
echo 'LOG: Install Openstack Client'
yum -y install python-openstackclient

echo
echo 'LOG: install MariaDB'
yum -y install mariadb mariadb-server python2-PyMySQL

echo
echo 'LOG: Create Openstack Configuration Database'
cat > /etc/my.cnf.d/openstack.cnf << EOF
[mysqld]
bind-address = $CONTROLLER_MANAGEMENT_IP

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8

EOF

echo
echo 'LOG: Start and Enable MariaDB'
systemctl enable mariadb.service
systemctl start mariadb.service

echo 
echo 'LOG: Configure Root Password'
mysql_secure_installation

echo
echo 'LOG: Install RabbitMQ'
yum -y install rabbitmq-server

echo
echo 'LOG: Start and Enable RabbitMQ'
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service

echo 'LOG: Add openstack user to RabbitMQ'
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

echo 
echo 'LOG: Install Memcached'
yum -y install memcached python-memcached

echo
echo 'LOG: Configure Memcached'
cat > /etc/sysconfig/memcached << EOF
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS="-l 127.0.0.1,::1,$CONTROLLER_MANAGEMENT_IP"

EOF

echo 
echo 'LOG: Start and Enable Memcached Service'
systemctl enable memcached.service
systemctl start memcached.service

echo
echo 'LOG: Install Etcd'
yum install etcd -y

echo
echo 'LOG: Configure Etcd'
cat > /etc/etcd/etcd.conf << EOF
[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://$CONTROLLER_MANAGEMENT_IP:2380"
ETCD_LISTEN_CLIENT_URLS="http://$CONTROLLER_MANAGEMENT_IP:2379"
ETCD_NAME="controller"

[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$CONTROLLER_MANAGEMENT_IP:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://$CONTROLLER_MANAGEMENT_IP:2379"
ETCD_INITIAL_CLUSTER="controller=http://$CONTROLLER_MANAGEMENT_IP:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"

EOF

echo
echo 'Start and Enable Etcd service'
systemctl enable etcd
systemctl start etcd

echo
echo '==========================================='
echo '           INSTALL SUCCESSFULLY            '
echo '==========================================='