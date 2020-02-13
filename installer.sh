#!/bin/bash

echo 'WARNING: please follow the "README.md" before run this script'

if [ "$EUID" -ne 0 ]; then
    echo 'Please run as root'
    exit
fi

function controller () {
    
    echo 'NOTE: if you have created network_var.sh before, select "n" '
    read -p 'Do you want to create network_var.sh [Y/n]? ' netvar
    
    if [[ "$netvar" = "Y" ]]; then
        ./network/network.sh
    elif [[ "$netvar" = "n" ]]; then
        :
    else
        echo 'Command not found'
        :
    fi

    echo 'NOTE: if you have created user_var.sh before, select "n" '
    read -p 'Do you want to create user_var.sh [Y/n]? ' uservar
    
    if [[ "$uservar" = "Y" ]]; then
        echo '=============================='
        echo '[1] One password to all services'
        echo '[2] Different password for each services'
        read -p '>> ' samepass
            if [ "$samepass" = "1" ]; then
                source ./user/user.sh
                same_pass
            elif [ "$samepass" = "2" ]; then
                source ./user/user.sh
                different_pass
            fi
    elif [[ "$uservar" = "n" ]]; then
        :
    else
        echo 'Command not found'
        :
    fi
    

    while [ true ]; do
        
        echo '=============================='
        echo 'SELECT SERVICE TO BE INSTALLED: '
        echo '=============================='
        echo '[1] Prerequisites'
        echo '[2] Keystone'
        echo '[3] Glance'
        echo '[4] Nova - controller'
        echo '[5] Neutron - controller'
        echo '[6] Horizon'
        echo '[7] Add Nova compute service'
        echo '[8] Add Neutron compute service'
        echo '[0] Exit'

        read -p '>> ' service

        if [ $service -eq '1' ]; then
            echo 'LOG: Install Prerequisites'
            ./service/prerequisites-controller.sh
        elif [ $service -eq '2' ]; then
            echo 'LOG: Install Keystone'
            ./service/keystone.sh
        elif [ $service -eq '3' ]; then
            echo 'LOG: Install Glance'
            ./service/glance.sh
        elif [ $service -eq '4' ]; then
            echo 'LOG: Install Nova - controller'
            ./service/nova-controller.sh
        elif [ $service -eq '5' ]; then
            echo 'LOG: Install Neutron - controller'
            ./service/neutron-controller.sh
        elif [ $service -eq '6' ]; then
            echo 'LOG: Install Horizon'
            ./service/horizon.sh
        elif [ $service -eq '7' ]; then
            echo 'LOG: Add Nova compute service'
            ./service/nova-add-compute.sh
        elif [ $service -eq '8' ]; then
            echo 'LOG: Add Neutron compute service'
            ./service/neutron-add-compute.sh
        elif [ $service -eq '0' ]; then
            echo 'Program Exited'
            exit
        else
            echo 'Command not found'
        fi

    done
}

function compute () {

    echo 'NOTE: if you have created network_var.sh before, select "n" '
    read -p 'Do you want to create network_var.sh [Y/n]? ' netvar
    
    if [[ "$netvar" = "Y" ]]; then
        ./network/network.sh
    elif [[ "$netvar" = "n" ]]; then
        :
    else
        echo 'Command not found'
        :
    fi

    echo 'NOTE: if you have created user_var.sh before, select "n" '
    read -p 'Do you want to create user_var.sh [Y/n]? ' uservar
    
    if [[ "$uservar" = "Y" ]]; then
        echo '=============================='
        echo '[1] One password to all services'
        echo '[2] Different password for each services'
        read -p '>> ' samepass
            if [ "$samepass" = "1" ]; then
                source ./user/user.sh
                same_pass
            elif [ "$samepass" = "2" ]; then
                source ./user/user.sh
                different_pass
            fi
    elif [[ "$uservar" = "n" ]]; then
        :
    else
        echo 'Command not found'
        :
    fi

    while [ true ]; do
        
        echo '=============================='
        echo 'SELECT SERVICE TO BE INSTALLED: '
        echo '=============================='
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
