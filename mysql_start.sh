#!/bin/bash
BACKUPVOL=/dockerbackup
DEFAULT_ROOT_NETWORKID="172.17.0.0/255.255.255.0"
DEFAULT_DBVOL=${PWD}/mysql
DEFAULT_CUSTOMCONFIG=${PWD}/my.cnf

read -p "Password for mysql root user (leave empty for existing DB): " ROOT_PASSWORD
if [ -z ${ROOT_PASSWORD} ]; then
    ENV_ROOT_PASSWORD=""
else
    ENV_ROOT_PASSWORD="-e MYSQL_ROOT_PASSWORD=${ROOT_PASSWORD}"
fi

read -p "Do you want to use custom network? (y/n) " yn
case $yn in
    [Yy]* ) 
            read -p "Custom network name : " CUSTOMNETWORKNAME
            LOCALNETWORK_IP=$(docker network inspect \
                ${CUSTOMNETWORKNAME} | grep Subnet | sed 's/\"//g' | cut -d: -f2 | cut -d/ -f1)
            MASK_LEN=$(docker network inspect \
                ${CUSTOMNETWORKNAME} | grep Subnet | sed 's/\"//g' | cut -d/ -f2 | cut -d, -f1)
	    LOCALNETWORK_IP=$(echo ${LOCALNETWORK_IP} | sed -e 's/^[ \t]*//')

            ONES=1111111111111111111111111111111111111111
            ZEROES=0000000000000000000000000000000000000000
            BITMAP_MASK=${ONES:0:${MASK_LEN}}${ZEROES:0:((24-$MASK_LEN))}
            LOCALNETWORK_MASK="$((2#${BITMAP_MASK:0:8}))"."$((2#${BITMAP_MASK:8:8}))"."$((2#${BITMAP_MASK:16:8}))"."$((2#${BITMAP_MASK:24:8}))"
            if [ ! -z $CUSTOMNETWORKNAME ]; then CUSTOMNETWORK=--net=${CUSTOMNETWORKNAME}; fi
            DEFAULT_ROOT_NETWORKID=${LOCALNETWORK_IP}/${LOCALNETWORK_MASK}
	    ;;
        * ) CUSTOMNETWORK=
	    ;;
esac

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
	    else
		   CUSTOMCONFIG="-v ${CUSTOMCONFIG}:/etc/my.cnf"
	    fi;;
        * ) CUSTOMCONFIG=
	    ;;
esac

#docker rm mysql
docker run \
	-h dbserver \
	-v ${DBVOL}:/var/lib/mysql \
	-v ${BACKUPVOL}:/backup \
	${CUSTOMCONFIG} \
	${ENV_ROOT_PASSWORD} \
	-e MYSQL_ROOT_HOST=${ALLOWED_ROOT_NETWORKID} \
	--name mysql \
	${CUSTOMNETWORK} \
	${FIXED_IP_ADDRESS} \
	-d tgiesela/mysql:v0.1



