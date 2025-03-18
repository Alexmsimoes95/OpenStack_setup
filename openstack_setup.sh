#!/bin/bash
# -------------------------------------------------------- 
# | Automation Script for OpenStack Prepare Installation |
# |							 |
# | Realized by: Alexandre Simoes			 |
# | Date: 2025-03-18					 |
# --------------------------------------------------------

$os_version=cat /etc/redhat_release
$user="stack"

echo "Support Docs URL: https://docs.openstack.org/devstack/rocky/guides/single-machine.html \n"

echo "-----------------------------------------"
echo "| OpenStack Installation Pre-Requisits |"
echo "-----------------------------------------"

user_check(){
	echo "\nCheck if Application User exists..."
	grep stack /etc/passwd
}

if [[ $user_check == 'stack' ]]; then
	echo "\nAdding users to sudoers.d..."
	sudo touch /etc/sudoers.d/stack
	echo "stack ALL=NOPASSWD: ALL" >> /etc/sudoers.d/stack
	sudo chmod u-w /etc/sudoers.d/stack
else
	echo "\nCreating Application User..."
	useradd -s /bin/bash -d /opt/stack -m stack
fi

echo "\nInstalling necessary packages..."
sudo yum install git net-tools vim -y

if [[ $os_version == 'Ubuntu' ]]; then
	echo "\nUpdating all packages..."
	sudo apt update -y
elif [[ $os_version == "Oracle Linux" ]]; then
	echo "\nUpdating all packages..."
	sudo yum update -y
 else
 	echo "\nUpdating all packages..."
  	sudo dnf update -y
fi

echo "\n----------------------------------"
echo "| OpenStack Installation Process |"
echo "----------------------------------"

echo "\nChanging to ${user} home directory.."
cd /opt/$user

echo "\nDownloading OpenStack Files..."
git clone https://git.openstack.org/openstack-dev/devstack
chown -R stack:stack ./devstack
cd devstack

echo "\nInsert the below requested values..."
config_requirements(){
	read -p "\nFLOATING_RANGE: " float
	read -p "\nFIXED_RANGE: " range
	read -p "\nFIXED_NETWORK_SIZE: " netsize
	read -p "\nFLAT_INTERFACE: " netinterface
	read -s -p "\nADMIN_PASSWORD: " admpasswd
	read -s -p "\nDATABASE_PASSWORD: " bdpasswd
	read -s -p "\nRABBIT_PASSWORD: " rabbitpasswd
	read -s -p "\nSERVICE_PASSWORD: " srvpasswd
}

echo "\nUpdating local.conf file..."
mv ./samples/local.conf ./samples/local.conf.original

echo "[[local|localrc]]" > ./samples/local.conf

config_file(){	
	echo "FLOATING_RANGE=${float}" >> ./samples/local.conf
	echo "FIXED_RANGE=${range}" >> ./samples/local.conf
	echo "FIXED_NETWORK_SIZE=${netsize}" >> ./samples/local.conf
	echo "FLAT_INTERFACE=${netinterface}" >> ./samples/local.conf
	echo "ADMIN_PASSWORD=${admpasswd}" >> ./samples/local.conf
	echo "DATABASE_PASSWORD=${bdpasswd}" >> ./samples/local.conf
	echo "RABBIT_PASSWORD=${rabbitpasswd}" >> ./samples/local.conf
	echo "SERVICE_PASSWORD=${srvpasswd}" >> ./samples/local.conf
}

echo "\nValidate the local config that will be presented below!"
cat ./samples/local.conf
sleep 5s
read -p "\nIs this config correct? [y/n] " configval

if [[ $configval == 'y' ]]; then
	./stack.sh
else
	config_requirements
	sleep 3s
	config_file
	sleep 3s
	cat ./samples/local.conf
	sleep 10s
	./stack.sh
fi
echo -n "\nPress any key to exit..."
for _ in {1..3}; do read -rs -n1 -t1 || printf ".";done;echo
