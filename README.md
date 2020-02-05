# Openstack Auto Installer

This is a script for auto Install Openstack Queens in centos7 with 2 node


## Requirement
- 2 nic for each node (controller & compute)

- Internet access for each node

## Prerequisites

### Network

- Configure your each node network like this :

```
    ========== FORMAT ============

    Hostname   : $SERVER_TYPE

    Interface  : $PROVIDER_INT_NAME
    IP Address : $PROVIDER_IP
    Netmask    : $PROVIDER_NETMASK
    Gateway    : $PROVIDER_GATEWAY

    Interface  : $MANAGEMENT_INT_NAME
    IP Address : $MANAGEMENT_IP
    Netmask    : $MANAGEMENT_NETMASK
    Gateway    : without gateway

    DNS Server : $DNS
```
provider network is a network that is connected to the internet that will be used as an external network

network management is a network used for internal communication in openstack clusters

- network Configuration example :
```
    ======= CONTROLLER NODE =======

    Hostname   : controller

    Interface  : enp2s0
    IP Address : 192.168.0.200
    Netmask    : 255.255.255.0
    Gateway    : 192.168.0.1

    Interface  : enp3s0
    IP Address : 10.1.1.10
    Netmask    : 255.255.255.0
    Gateway    : without gateway

    DNS Server : 8.8.8.8
```

```
    ======== COMPUTE NODE =========

    Hostname   : compute

    Interface  : enp2s0
    IP Address : 192.168.0.210
    Netmask    : 255.255.255.0
    Gateway    : 192.168.0.1

    Interface  : enp3s0
    IP Address : 10.1.1.20
    Netmask    : 255.255.255.0
    Gateway    : without gateway

    DNS Server : 8.8.8.8
```

NOTE: *This IP address may change depends on your networking.*

### Host Mapping

- Configure on each node

```
    nano /etc/hosts

    192.168.0.200 controller
    192.168.0.210 compute
```
NOTE: *This IP address may change depends on your networking.*

- verification
```
    ping -c 3 controller
    ping -c 3 compute
    ping -c 3 10.1.1.10
    ping -c 3 10.1.1.20
    ping -c 3 google.com
```
make sure the ping results are successful

### User and Password

OpenStack requires a user and password for each service, when running *installer.sh*, you will be asked to enter a password for a number of services as below which will be stored on *./user/user_var.sh*

| Password       | Description     |
| :------------- | :----------: |
| DBROOT_PASS | Root password for the database |
|  ADMIN_PASS | Password of user admin |
|  GLANCE_PASS | Password of Image service user glance |
|  GLANCEDB_PASS | Database password for Image service |
| KEYSTONE_DBPASS | Database password of Identity service | 
|  NEUTRON_PASS | Password of Networking service user neutron |
|  NEURONDB_PASS | Database password for the Networking service |
|  NOVA_PASS | Password of Compute service user nova |
|  NOVADB_PASS | Database password for Compute service |
| PLACEMENT_PASS | Password of the Placement service user placement |
|  RABBIT_PASS | Password of RabbitMQ user openstack |
|  METADATA_SECRET | Secret for the metadata proxy |

### ssh without password

Run this command on each node

- Controller node

```
    # ssh-keygen -t rsa
    # ssh-copy-id -i ~/.ssh/id_rsa.pub root@$COMPUTE_PROVIDER_IP
```
- Compute node
```
    # ssh-keygen -t rsa
    # ssh-copy-id -i ~/.ssh/id_rsa.pub root@$CONTROLLER_PROVIDER_IP
```
replace *$COMPUTE_PROVIDER_IP* and *$CONTROLLER_PROVIDER_IP* depens on your networking

## Instsallation

__Comming soon__