#!/bin/bash

MYSQL_IMAGE="mysql:5.7"
WORDPRESS_IMAGE="wordpress:4.9.2-php7.2-apache"
ENV_FILE="wp-env.sh"

PORT=80

MYSQL_VOLUME="$PWD/mysql-data"
WORDPRESS_VOLUME="$PWD/wp-content"

MYSQL_HOST="mysql"
WP_HOST="WORDPRESS"
WP_NETWORK="WP_NETWORK"


docker network create --driver bridge WP_NETWORK

for DIR in ${MYSQL_VOLUME} ${WORDPRESS_VOLUME}; do
  mkdir -p $DIR || echo "$DIR already exists"
done

docker run --name ${MYSQL_HOST} \
           --network WP_NETWORK \
           --volume "${MYSQL_VOLUME}:/var/lib/mysql" \
           --env-file ${ENV_FILE} \
           --detach \
           ${MYSQL_IMAGE}

# Wait for mysql server to accept connections
#Better solutions exist such as listening ports in a loop
#we can implement it in the future
echo "Wait for MYSQL server to finish initialization"
sleep 20

docker run --name ${WP_HOST} \
           --network WP_NETWORK \
           --publish $PORT:80 \
           --volume "${WORDPRESS_VOLUME}:/var/www/html/wp-content" \
           --env-file ${ENV_FILE} \
           --detach \
           --publish-all \
           $WORDPRESS_IMAGE
