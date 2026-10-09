#!/bin/bash

if [[ -z "$EPAPLUGIN_URL" ]] ; then
    EPAPLUGIN_URL=$(
        wget -qO- https://www.citrix.com/downloads/citrix-endpoint-analysis/plug-ins/EPA-Clients-Linux.html \
            | sed -ne '/nsepa\.deb/ s/<a .* rel="\(.*\)" id="downloadcomponent_co.*">/https:\1/p' \
            | sed -e 's/\r//g' \
            | sed 's/[[:blank:]]//g'
        )
fi

echo "Using Citrix EPA Plug In download URL: ${EPAPLUGIN_URL}"
curl "${EPAPLUGIN_URL}" --output /tmp/epaplugin.deb

DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "nsepa app_protection/install_app_protection select yes"
apt-get install -f /tmp/epaplugin.deb
