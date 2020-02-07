#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as sudo'
    exit
fi

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
echo '==========================================='
echo '           INSTALL SUCCESSFULLY            '
echo '==========================================='