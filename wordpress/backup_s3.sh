#!/bin/bash
##BACKUP the database
FOLDER="/home/ubuntu/wordpress"
now_s3=`date +'%Y/%m/%d'`

MYSQL_FOLDER=$FOLDER/mysql-data
WP_FOLDER=$FOLDER/wp-content

##cp mysql
aws s3 cp --recursive ${MYSQL_FOLDER}  s3://dekkerlab-wordpress/db-backups/${now_s3}/ &> /home/ubuntu/aws_backup_result.txt

##cp wordpress
aws s3 cp --recursive ${WP_FOLDER}  s3://dekkerlab-wordpress/wp-backups/${now_s3}/ &> /home/ubuntu/aws_backup_result.txt
