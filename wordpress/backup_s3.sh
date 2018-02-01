#!/bin/bash
##BACKUP WORDPRESS SITE to AWS S3
##
## 1) Back up Mysql database
## 2) backup wp-contents folder
##
## Note that the foile paths are relative
## Run this scrip in the directory of the script itself

FOLDER=`pwd`
now_s3=`date +'%Y/%m/%d'`

MYSQL_FOLDER=mysql-data
WP_FOLDER=wp-content

if [ ! -d ${WP_FOLDER} ];
then
  echo The folder ${WP_FOLDER} does not exist.
  exit 1
fi

MYSQL_BACKUP_FILE=`date +'mysql-%Y-%m-%d-backup.sql.gz'`
WP_BACKUP_FILE=`date +'wp-%Y-%m-%d-backup.tar.gz'`

MYSQL_S3_FILE="s3://dekkerlab-wordpress/db-backups/${now_s3}/${MYSQL_BACKUP_FILE}"
WP_S3_FILE="s3://dekkerlab-wordpress/wp-backups/${now_s3}/${WP_BACKUP_FILE}"

## Dump Mysql into a gzipped text file
## and copy it to s3 and then delete it from local folder
docker exec mysql /usr/bin/mysqldump -u root \
  --password=wordpress wordpress | gzip > ${MYSQL_BACKUP_FILE}

aws s3 cp ${MYSQL_BACKUP_FILE} ${MYSQL_S3_FILE}


#######################################################

## Tar the wp-contetn file and copy it to S3
tar -czf ${WP_BACKUP_FILE} ${WP_FOLDER}
aws s3 cp ${WP_BACKUP_FILE} ${WP_S3_FILE}

sleep 1
rm ${MYSQL_BACKUP_FILE} ${WP_BACKUP_FILE}

echo DONE!
echo Backed up the files ${MYSQL_S3_FILE} and ${WP_S3_FILE}.
