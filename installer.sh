#!/bin/bash

echo 'WARNING: please follow the "README.md" before run this script'

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

function network_ip () {
    echo '=========== CONTROLLER ============'
    read -p 'Enter your controller provider ip address: ' CONTROLLER_PROVIDER_IP
    read -p 'Enter your controller management ip address: 'CONTROLLER_MANAGEMENT_IP
    echo '============= COMPUTE =============='
    read -p 'Enter your compute provider ip address: ' COMPUTE_PROVIDER_IP
    read -p 'Enter your compute management ip address: 'COMPUTE_MANAGEMENT_IP
}

function user_password () {
    echo '=========== USER AND PASSWORD ============'
    echo 'create user and password for openstack service'
    USER_PASS=./user_pass_openstack.txt

    read -p 'DBROOT_PASS : ' DBROOT_PASS
    echo 'DBROOT_PASS = '$DBROOT_PASS >> $USER_PASS

    read -p 'ADMIN_PASS : ' ADMIN_PASS
    echo 'ADMIN_PASS = '$ADMIN_PASS >> $USER_PASS

    read -p 'GLANCE_PASS : ' GLANCE_PASS
    echo 'GLANCE_PASS = '$GLANCE_PASS >> $USER_PASS

    read -p 'GLANCEDB_PASS : ' GLANCEDB_PASS
    echo 'GLANCEDB_PASS = '$GLANCEDB_PASS >> $USER_PASS

    read -p 'KEYSTONE_DBPASS : ' KEYSTONE_DBPASS
    echo 'KEYSTONE_DBPASS = '$KEYSTONE_DBPASS >> $USER_PASS

    read -p 'NEUTRON_PASS : ' NEUTRON_PASS
    echo 'NEUTRON_PASS = '$NEUTRON_PASS >> $USER_PASS

    read -p 'NEUTRONDB_PASS : ' NEUTRONDB_PASS
    echo 'NEUTRONDB_PASS = '$NEUTRONDB_PASS >> $USER_PASS

    read -p 'NOVA_PASS : ' NOVA_PASS
    echo 'NOVA_PASS = '$NOVA_PASS >> $USER_PASS

    read -p 'NOVADB_PASS : ' NOVADB_PASS
    echo 'NOVADB_PASS = '$NOVADB_PASS >> $USER_PASS

    read -p 'PLACEMENT_PASS : ' PLACEMENT_PASS
    echo 'PLACEMENT_PASS = '$PLACEMENT_PASS >> $USER_PASS

    read -p 'RABBIT_PASS : ' RABBIT_PASS
    echo 'RABBIT_PASS = '$RABBIT_PASS >> $USER_PASS

    read -p 'METADATA_SECRET : ' METADATA_SECRET
    echo 'METADATA_SECRET = '$METADATA_SECRET >> $USER_PASS
}

function prerequisites () {
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
}

function controller () {
    prerequisites

}

function compute () {
    prerequisites
}

echo 'Select the type of server to be installed: '
echo '[1] = controller'
echo '[2] = compute'
read -p '>> ' server_type

if [ $server_type = '1' ]; then
    controller
elif [ $server_type = '2' ]; then
    compute
fi