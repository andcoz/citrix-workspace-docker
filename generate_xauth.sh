#!/bin/bash
echo "Generating XAuth token"
XAUTH_DOCKER="./xauth_docker"
touch "$XAUTH_DOCKER"
xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH_DOCKER" nmerge -
chmod 644 "$XAUTH_DOCKER"