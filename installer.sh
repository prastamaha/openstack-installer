#!/bin/bash

echo 'WARNING: please follow the "README.md" before run this script'

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

function controller () {
    
    ./network/network.sh
    ./user/user.sh

    while [ true ]; do
        
        echo '=============================='
        echo 'SELECT SERVICE TO BE INSTALLED: '
        echo '[1] Prerequisites'
        echo '[2] Keystone'
        echo '[3] Nova - controller'
        echo '[4] Nova add compute node to database'
        echo '[5] Neutron - controller'
        echo '[6] Horizon'
        echo '[0] Exit'

        read -p '>> ' service

        if [ $service -eq '1' ]; then
            echo 'LOG: Install Prerequisites'
            ./service/prerequisites-controller.sh
        elif [ $service -eq '2' ]; then
            echo 'LOG: Install Keystone'
            ./service/keystone.sh
        elif [ $service -eq '3' ]; then
            echo 'LOG: Install Nova - controller'
            ./service/nova-controller.sh
        elif [ $service -eq '4' ]; then
            echo 'LOG: Add Nova Compute to database'
            ./service/nova-add-compute.sh
        elif [ $service -eq '5' ]; then
            echo 'LOG: Install Neutron - controller'
            ./service/neutron-controller.sh
        elif [ $service -eq '6' ]; then
            echo 'LOG: Install Horizon'
            ./service/horizon.sh
        elif [ $service -eq '0' ]; then
            echo 'Program Exited'
            exit
        else
            echo 'Command not found'
        fi

    done
}

function compute () {

    ./network/network.sh
    ./user/user.sh
    
    while [ true ]; do
        
        echo '=============================='
        echo 'SELECT SERVICE TO BE INSTALLED: '
        echo '[1] Prerequisites'
        echo '[2] Nova - compute'
        echo '[3] Neutron - compute'
        echo '[0] Exit'

        read -p '>> ' service

        if [ $service -eq '1' ]; then
            echo 'LOG: Install Prerequisites'
            ./service/prerequisites-compute.sh
        elif [ $service -eq '2' ]; then
            echo 'LOG: Install Nova - compute'
            ./service/nova-compute.sh
        elif [ $service -eq '3' ]; then
            echo 'LOG: Install Neutron - compute'
            ./service/neutron-compute.sh
        elif [ $service -eq '0' ]; then
            echo 'Program Exited'
            exit
        else
            echo 'Command not found'
        fi

    done
}

echo 'Select the type of server to be installed: '
echo '[1] Controller'
echo '[2] Compute'
read -p '>> ' server_type

if [ $server_type = '1' ]; then
    controller
elif [ $server_type = '2' ]; then
    compute
fi