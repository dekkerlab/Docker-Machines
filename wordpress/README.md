# WORDPRESS SERVER

This is a set of scripts for managing wordpress servers in the cloud.
The scripts automate spinning up docker machines, backup and recovery.

There are two containers to run the wordpress server.

**1. Apache & Wordpress:** Contains Apache with PHP and Wordpress
**2. MySQL:** MySQL Database Server 

**IMPORTANT:**
The paths in most scripts are relative. So please change your working directory
to the scripts folder (i.e., /path/to/Docker-Machines/wordpress), and then run the scripts.

**NOTE:**
For backup and recovery AWS S3 must be configured in the host machine.

## PORT
The scripts `run_server.sh` and `recover_from_s3.sh` uses a variable called *PORT*. 
The web server is going to use this port.
For production use, set this value to 80. If you want to run it locally, you can give an avaialble port number such as 8080.

## Running For the First Time
If you want to run it for the first time, run

`bash run_server.sh`

This will create WP_NETWORK and run MySQL and WORDPRESS containers. Once you run the script,
give 20-30 seconds for the server to finish initialization.

## Stopping the Containers

`bash stop_containers.sh`

## Backing up the Containers to AWS S3
While the containers are running, you can take a backup of the containers as follows.

`bash backup_s3.sh`

Please note that AWS S3 moust be configured in the host machine for this.
On some AWS EC2 images of the lab, this comes readily available.

## Recovering a Backup in S3
You can go back to a particular backup by providing the backup date in the format
*YYYY-MM-DD*

Note that that, when a backup is taken, the backup location and file names will be determined by the date, the backup was  taken. Also, keep in mind that, if the backup for that particular date does not exist, you'll get an error.

So, for example, if you want to recover a page from February 1st, 2018, you can run

`bash recover_from_s3.sh 2018-02-01`

## Environment Variables
The environment variables for both docker machines are stored in the file
wp-env.sh. This file is needed for running the docker machines and provided in the `--env-file` argument.

## docker-compose.yml
Do not use this for running containers. Currently, we keep this file for archival purposes.
The problem with using docker-compose is that Wordpress server does not wait long enoigh for the MySQL server to initialize.

## Wait for the MySQL Server to Initialize
We use

`sleep 20`

in our scripts so that Wordpress server waits for the docker server to initialize. Otherwise, it won't be able to make connection. A better solution could be using a script in the Wordpress server that checks MySQL server port.

## Automated Backups
One way of doing automated backups is setting up a crontab job to run `backup_s3.sh` script periodically.


