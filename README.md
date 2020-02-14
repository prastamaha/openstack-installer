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
    
    # MANAGEMENT NETWORK
    Interface  : $MANAGEMENT_INT_NAME
    IP Address : $MANAGEMENT_IP
    Netmask    : $MANAGEMENT_NETMASK
    Gateway    : $MANAGEMENT_GATEWAY
    
    # PROVIDER NETWORK
    Interface  : $PROVIDER_INT_NAME
    IP Address : $PROVIDER_IP
    Netmask    : $PROVIDER_NETMASK
    Gateway    : without gateway

    DNS Server : $DNS
```
Management network is a network requires a gateway to provide Internet access to all nodes for administrative purposes such as package installation, security updates, DNS, and NTP.

Provider network is a network that will be used as an external network for the instance

- network Configuration example :
```
    ======= CONTROLLER NODE =======

    Hostname   : controller

    # MANAGEMENT NETWORK
    Interface  : enp2s0
    IP Address : 192.168.0.200
    Netmask    : 255.255.255.0
    Gateway    : 192.168.0.1

    # PROVIDER NETWORK
    Interface  : enp3s0
    IP Address : 10.1.1.10
    Netmask    : 255.255.255.0
    Gateway    : without gateway

    DNS Server : 8.8.8.8
```

```
    ======== COMPUTE NODE =========

    Hostname   : compute
    
    # MANAGEMENT NETWORK
    Interface  : enp2s0
    IP Address : 192.168.0.210
    Netmask    : 255.255.255.0
    Gateway    : 192.168.0.1

    # PROVIDER NETWORK
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
| KEYSTONEDB_PASS | Database password of Identity service | 
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

1. Clone the repository
```
# git clone https://github.com/prastamaha/openstack-installer.git
```

2. Go to openstack-installer directory
```
# cd openstack-installer/
```

3. Run the installer,  First we are going to configure controller, choose 1
```
# ./installer.sh
    
    WARNING: please follow the "README.md" before run this script
    Select the type of server to be installed: 
    [1] Controller
    [2] Compute
    >> 1
```

4. Will appear the banner for create network_var.sh, Press Y
```
    NOTE: if you have created network_var.sh before, select "n" 
    Do you want to create network_var.sh [Y/n]? Y
    
    follow the instruction
    network_var.sh will be placed on ~/openstack-installer/network/network_var.sh
```

5. Will appear the banner for create network_var.sh, Press Y
```
    NOTE: if you have created user_var.sh before, select "n" 
    Do you want to create user_var.sh [Y/n]? Y
    
    follow the instruction
    user_var.sh will be placed on ~/openstack-installer/user/user_var.sh
```

6. will appear the menu of service to be installed
   press 1-6 to install openstack basic service in controller node
```
    ==============================
    SELECT SERVICE TO BE INSTALLED: 
    ==============================
    [1] Prerequisites
    [2] Keystone
    [3] Glance
    [4] Nova - controller
    [5] Neutron - controller
    [6] Horizon
    [7] Add Nova compute service
    [8] Add Neutron compute service
    [0] Exit
    >>
    
    follow instruction
```

7. in compute node follow step 1-2

8. Run the installer, we are going to configure compute node, choose 2
```
# ./installer.sh
    
    WARNING: please follow the "README.md" before run this script
    Select the type of server to be installed: 
    [1] Controller
    [2] Compute
    >> 2
```

9. next, follow step 4-5

10. After that, will appear the menu of service to be installed
    press 1-3 to install openstack basic service in compute node
```
    ==============================
    SELECT SERVICE TO BE INSTALLED: 
    [1] Prerequisites
    [2] Nova - compute
    [3] Neutron - compute
    [0] Exit
    >>

    follow instruction
```
11. We are go back to controller node
    press 7-8 to add nova and neutron service in compute node
```
    ==============================
    SELECT SERVICE TO BE INSTALLED: 
    ==============================
    [1] Prerequisites
    [2] Keystone
    [3] Glance
    [4] Nova - controller
    [5] Neutron - controller
    [6] Horizon
    [7] Add Nova compute service
    [8] Add Neutron compute service
    [0] Exit
    >>
    
    follow instruction
```

12. check the nova agent (run on controller node)
```
# openstack compute service list
```

13. make sure nova agent list will appear like this
```
    +----+------------------+------------+----------+---------+-------+----------------------------+
    | ID | Binary           | Host       | Zone     | Status  | State | Updated At                 |
    +----+------------------+------------+----------+---------+-------+----------------------------+
    |  1 | nova-consoleauth | controller | internal | enabled | up    | 2020-02-13T03:55:26.000000 |
    |  2 | nova-conductor   | controller | internal | enabled | up    | 2020-02-13T03:55:28.000000 |
    |  3 | nova-scheduler   | controller | internal | enabled | up    | 2020-02-13T03:55:27.000000 |
    |  6 | nova-compute     | compute    | nova     | enabled | up    | 2020-02-13T03:55:21.000000 |
    +----+------------------+------------+----------+---------+-------+----------------------------+
```

14. check the neutron agent (run on controller node)
```
# openstack network agent list
```

15. make sure neutron agent list will appear like this
```
+--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
| ID                                   | Agent Type         | Host       | Availability Zone | Alive | State | Binary                    |
+--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+
| 0b92a6a7-15c8-46a8-a270-5cf1adbc3faa | DHCP agent         | controller | nova              | :-)   | UP    | neutron-dhcp-agent        |
| 11f455a5-21f3-46eb-a6c2-b20ab4b56d25 | L3 agent           | controller | nova              | :-)   | UP    | neutron-l3-agent          |
| 2be94656-8768-4f18-8a5f-0aa29ab5da80 | Open vSwitch agent | controller | None              | :-)   | UP    | neutron-openvswitch-agent |
| a0e2c1ba-2780-4c80-899b-b8c121af5713 | Metadata agent     | controller | None              | :-)   | UP    | neutron-metadata-agent    |
| b2fc359a-5188-43f5-9bc8-d2db29f4a169 | Open vSwitch agent | compute    | None              | :-)   | UP    | neutron-openvswitch-agent |
+--------------------------------------+--------------------+------------+-------------------+-------+-------+---------------------------+

```

16. if host compute doesnt appear in agent list, Reboot all nodes and run this command when the all nodes have bootup
```
# systemctl restart openstack-nova* neutron*
```

## Environment
if you want install openstack on virtualization qemu-kvm, you need add configuration on your controller node like this:
```
nano /etc/nova/nova.conf

virt_type=qemu
```
then restart nova and service
```
systemctl restart openstack-nova*
```
