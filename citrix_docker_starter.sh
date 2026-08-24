#!/bin/bash

whoami=`logname`
export myID="$(id -u $whoami)"
echo "Running user ID: $myID"
if  docker image inspect citrix-workspace:latest >/dev/null 2>&1; then
    echo "Image exists, continue to start up"
    ./generate_xauth.sh
    echo "Starting container"
    docker compose up -d
else
    while true; do
    read -p "Image doest not exists, do you want to build it now? [y/n]" yn
    case $yn in
        [Yy]* ) docker compose build citrix-workspace; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
fi