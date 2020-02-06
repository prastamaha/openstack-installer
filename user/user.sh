#!/bin/bash

function different_pass() {
    function user_head () {
        echo '=========== USER AND PASSWORD ============'
        echo 'create user and password for openstack service'
        echo 'WARNING: all your password will be stored at user_pass_openstack.txt'
        USER_PASS=./user/user_var.sh
    }
    user_head

    function DBROOT_PASS () {
        read -p 'DBROOT_PASS : ' DBROOT_PASS
        echo 'DBROOT_PASS='$DBROOT_PASS >> $USER_PASS
    }
    DBROOT_PASS

    function ADMIN_PASS () {
        read -p 'ADMIN_PASS : ' ADMIN_PASS
        echo 'ADMIN_PASS='$ADMIN_PASS >> $USER_PASS
    }
    ADMIN_PASS

    function GLANCE_PASS () {
        read -p 'GLANCE_PASS : ' GLANCE_PASS
        echo 'GLANCE_PASS='$GLANCE_PASS >> $USER_PASS
    }
    GLANCE_PASS

    function GLANCEDB_PASS () {
        read -p 'GLANCEDB_PASS : ' GLANCEDB_PASS
        echo 'GLANCEDB_PASS='$GLANCEDB_PASS >> $USER_PASS
    }
    GLANCEDB_PASS

    function KEYSTONEDB_PASS () {
        read -p 'KEYSTONEDB_PASS : ' KEYSTONEDB_PASS
        echo 'KEYSTONEDB_PASS='$KEYSTONEDB_PASS >> $USER_PASS
    }
    KEYSTONEDB_PASS

    function NEUTRON_PASS () {
        read -p 'NEUTRON_PASS : ' NEUTRON_PASS
        echo 'NEUTRON_PASS='$NEUTRON_PASS >> $USER_PASS
    }
    NEUTRON_PASS

    function NEUTRONDB_PASS () {
        read -p 'NEUTRONDB_PASS : ' NEUTRONDB_PASS
        echo 'NEUTRONDB_PASS='$NEUTRONDB_PASS >> $USER_PASS
    }
    NEUTRONDB_PASS

    function NOVA_PASS () {
        read -p 'NOVA_PASS : ' NOVA_PASS
        echo 'NOVA_PASS='$NOVA_PASS >> $USER_PASS
    }
    NOVA_PASS

    function NOVADB_PASS () {
        read -p 'NOVADB_PASS : ' NOVADB_PASS
        echo 'NOVADB_PASS='$NOVADB_PASS >> $USER_PASS
    }
    NOVADB_PASS

    function PLACEMENT_PASS () {
        read -p 'PLACEMENT_PASS : ' PLACEMENT_PASS
        echo 'PLACEMENT_PASS='$PLACEMENT_PASS >> $USER_PASS
    }
    PLACEMENT_PASS

    function RABBIT_PASS () {
        read -p 'RABBIT_PASS : ' RABBIT_PASS
        echo 'RABBIT_PASS='$RABBIT_PASS >> $USER_PASS
    }
    RABBIT_PASS

    function METADATA_SECRET () {
        read -p 'METADATA_SECRET : ' METADATA_SECRET
        echo 'METADATA_SECRET='$METADATA_SECRET >> $USER_PASS
    }
    METADATA_SECRET
}

function same_pass() {
     function user_head () {
        echo '=========== USER AND PASSWORD ============'
        echo 'create user and password for openstack service'
        echo 'WARNING: all your password will be stored at user_pass_openstack.txt'
        USER_PASS=./user/user_var.sh
    }
    user_head

    function read_pass() {
        read -p 'PASSWORD FOR ALL SERVICES : ' all_pass
        echo 'DBROOT_PASS='$all_pass >> $USER_PASS
        echo 'ADMIN_PASS='$all_pass >> $USER_PASS
        echo 'GLANCE_PASS='$all_pass >> $USER_PASS
        echo 'GLANCEDB_PASS='$all_pass >> $USER_PASS
        echo 'KEYSTONEDB_PASS='$all_pass >> $USER_PASS
        echo 'NEUTRON_PASS='$all_pass >> $USER_PASS
        echo 'NEUTRONDB_PASS='$all_pass >> $USER_PASS
        echo 'NOVA_PASS='$all_pass >> $USER_PASS
        echo 'NOVADB_PASS='$all_pass >> $USER_PASS
        echo 'PLACEMENT_PASS='$all_pass >> $USER_PASS
        echo 'RABBIT_PASS='$all_pass >> $USER_PASS
        echo 'METADATA_SECRET='$all_pass >> $USER_PASS
    }
    read_pass
}
chmod +x user/user_var.sh