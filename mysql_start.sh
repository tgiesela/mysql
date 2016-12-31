#!/bin/bash

DEFAULT_ROOT_NETWORKID="172.17.0.1/255.255.255.0"
DEFAULT_DBVOL=${PWD}/mysql
DEFAULT_CUSTOMCONFIG=${PWD}/custom.cnf

read -p "Password for mysql root user: " ROOT_PASSWORD

read -p "Ip-address/Mask to give root remote access (${DEFAULT_ROOT_NETWORKID}):" ALLOWED_ROOT_NETWORKID
if [ -z $ALLOWED_ROOT_NETWORKID ]; then
    ALLOWED_ROOT_NETWORKID=${DEFAULT_ROOT_NETWORKID} 
fi

read -p "Fixed ip-address for mysql server: " FIXED_IP_ADDRESS
if [ -z $FIXED_IP_ADDRESS ]; then 
    FIXED_IP_ADDRESS=; 
else 
    FIXED_IP_ADDRESS=--ip=${FIXED_IP_ADDRESS}; 
fi 

read -p "Folder to store mysql database (${DEFAULT_DBVOL}) : " DBVOL
if  [ -z $DBVOL ]; then
   DBVOL=${DEFAULT_DBVOL}
fi

read -p "Do you want to use a custom mysql configuration stored outside the container?(y/n) " yn
case $yn in
    [Yy]* ) 
	    read -p "Custom mysql config file (${DEFAULT_CUSTOMCONFIG}) : " CUSTOMCONFIG
	    if  [ -z $CUSTOMCONFIG ]; then
		   CUSTOMCONFIG="-v ${DEFAULT_CUSTOMCONFIG}:/custom.cnf:/etc/my.cnf"
	    fi;;
        * ) CUSTOMCONFIG=
	    ;;
esac

read -p "Do you want to use custom network? (y/n) " yn
case $yn in
    [Yy]* ) 
	    read -p "Custom network name : " CUSTOMNETWORKNAME
	    if  [ -z $CUSTOMNERWORKNAME ]; then
		   CUSTOMNETWORK="--net ${CUSTOMNETWORKNAME}"
	    fi;;
        * ) CUSTOMNETWORK=
	    ;;
esac

#docker rm mysql
docker run \
	-h dbserver \
	-v ${DBVOL}:/var/lib/mysql \
	${CUSTOMCONFIG} \
	-e MYSQL_ROOT_PASSWORD=$ROOT_PASSWORD \
	-e MYSQL_ROOT_HOST=${ALLOWED_ROOT_NETWORKID} \
	--name mysql \
	${CUSTOMNETWORK} \
	${FIXED_IP_ADDRESS} \
	-d tgiesela/mysql:v0.1



