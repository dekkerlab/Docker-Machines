#!/bin/bash
## RECOVER WORDPRESS SITE FROM A PARTICULAR AWS S3 BACKUP
##
## 1) RECOVER Mysql database
## 2) RECOVER wp-contents folder
##
## IMPORTANT
## Usage: bash recover_s3.sh YYYY-MM-DD
## Note that you need to specify a particular date for recovery
## The date is in the format YYYY-MM-DD
##
## NOTE:
## The first arguments is the date: Example: 2018-02-01
## This determines the date of the backup to recover from
##
## IMPORTNAT: The following does not solve the serialization problem
## So, if you are using the site to a new doamin, use Migrate DB plugin
## You can have more detailed info in the following link:
## https://neliosoftware.com/blog/wordpress-migration-problems-and-how-to-fix-them/
## 
##
## The second and third arguments are optional
## If you are moving from one domain name to another domain
## then you should provide
## $2: (i.e., second argument) old domain
## $3: (i.e., third argument) new domain
##
## Example Usage:
##
## bash recover_s3.sh 2018-02-01 localhost www.dekkerlab.org


MYSQL_IMAGE="mysql:5.7"
WORDPRESS_IMAGE="wordpress:4.9.2-php7.2-apache"
ENV_FILE="wp-env.sh"

PORT=80

MYSQL_VOLUME="$PWD/mysql-data"
WORDPRESS_VOLUME="$PWD/wp-content"

MYSQL_HOST="mysql"
WP_HOST="WORDPRESS"


FOLDER=`pwd`
DATE_STRING=$1
s3_date_path=`echo ${DATE_STRING} | sed "s/-/\//g"`

MYSQL_FOLDER=$FOLDER/mysql-data
WP_FOLDER=$FOLDER/wp-content

MYSQL_BACKUP_FILE="mysql-${DATE_STRING}-backup.sql.gz"
WP_BACKUP_FILE="wp-${DATE_STRING}-backup.tar.gz"

MYSQL_S3_FILE="s3://dekkerlab-wordpress/db-backups/${s3_date_path}/${MYSQL_BACKUP_FILE}"
WP_S3_FILE="s3://dekkerlab-wordpress/wp-backups/${s3_date_path}/${WP_BACKUP_FILE}"

## Check that the backup files exist
WP_BACKUP_EXISTS=`aws s3 ls ${WP_S3_FILE} | wc -l`
MYSQL_BACKUP_EXISTS=`aws s3 ls ${MYSQL_S3_FILE} | wc -l`

if [ ${WP_BACKUP_EXISTS} -eq 0 ];
then
  echo Error: ${WP_S3_FILE} does not exist!
  exit 1
fi

if [ ${MYSQL_BACKUP_EXISTS} -eq 0 ];
then
  echo Error: ${MYSQL_S3_FILE} does not exist!
  exit 1
fi

#######################################
## Stop the containers
WP_WORKING=`docker ps -a | grep -E " ${WP_HOST}" | wc -l`
MYSQL_WORKING=`docker ps -a | grep -E " ${MYSQL_HOST}" | wc -l`

if [ ${MYSQL_WORKING} -gt 0 ];
then
  echo stopping mysql container...
  docker stop ${MYSQL_HOST}
  docker rm ${MYSQL_HOST}
fi

if [ ${WP_WORKING} -gt 0 ];
then
  echo stopping wordpress container...
  docker stop ${WP_HOST}
  docker rm ${WP_HOST}
fi

## Arrange Network
NETWORK_EXISTS=`docker network ls | grep "WP_NETWORK" | wc -l`
if [ ${NETWORK_EXISTS} -eq 0 ];
then
  echo creating WP_NETWORK
  docker network create --driver bridge WP_NETWORK
fi

sleep 5

##
if [ -d ${WP_FOLDER} ];
then
  sudo rm -rf ${WP_FOLDER}
fi

##
if [ -d ${MYSQL_FOLDER} ];
then
  sudo rm -rf ${MYSQL_FOLDER}
fi

### Get the backup files
aws s3 cp ${MYSQL_S3_FILE} ${MYSQL_BACKUP_FILE}
aws s3 cp ${WP_S3_FILE} ${WP_BACKUP_FILE}

###########################################
## Recover the database first

## Initialize the database
docker run --name ${MYSQL_HOST} \
           --network WP_NETWORK \
           --volume "${MYSQL_VOLUME}:/var/lib/mysql" \
           --env-file ${ENV_FILE} \
           --detach \
           ${MYSQL_IMAGE}

echo "Wait for MYSQL server to finish initialization"
sleep 20

## If you are moving backup from one domain to another domain
## then you need to fix the links in the database
if [ ! -z $2 ] && [ ! -z $3 ];
then
   echo Replacing $2 with $3 in the database
   zcat ${MYSQL_BACKUP_FILE} | sed "s/$2/$3/g" | gzip > ${MYSQL_BACKUP_FILE}.tmp
   mv ${MYSQL_BACKUP_FILE}.tmp ${MYSQL_BACKUP_FILE}
fi

## Recover wordpress database from the sql file
zcat ${MYSQL_BACKUP_FILE} | docker exec -i ${MYSQL_HOST}\
    /usr/bin/mysql -u root --password=wordpress wordpress

############################################
## Recover the wordpress files next
tar -xzf ${WP_BACKUP_FILE}

sudo chmod 777 ${WORDPRESS_VOLUME} -R

docker run --name ${WP_HOST} \
           --network WP_NETWORK \
           --publish $PORT:80 \
           --volume "${WORDPRESS_VOLUME}:/var/www/html/wp-content" \
           --env-file ${ENV_FILE} \
           --detach \
           --publish-all \
           $WORDPRESS_IMAGE

rm ${MYSQL_BACKUP_FILE} ${WP_BACKUP_FILE}

docker ps -f "name=mysql" -f "name=WORDPRESS"

echo Wait a little for the server to iitialize
sleep 10
echo DONE!
