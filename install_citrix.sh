#!/bin/bash
ICACLIENT_URL=$(wget -qO- https://www.citrix.com/downloads/workspace-app/linux/workspace-app-for-linux-latest.html | sed -ne '/icaclient.*amd64\.deb/ s/<a .* rel="\(.*\)" id="downloadcomponent_co.*">/https:\1/p' | sed -e 's/\r//g' | sed 's/[[:blank:]]//g')

echo "Using Citrix Workspace download URL: ${ICACLIENT_URL}"
curl "${ICACLIENT_URL}" --output /tmp/icaclient.deb
    
USB_PACKAGE_URL=$(wget -qO- https://www.citrix.com/downloads/workspace-app/linux/workspace-app-for-linux-latest.html | sed -ne '/ctxusb.*amd64\.deb/ s/<a .* rel="\(.*\)" id="downloadcomponent_co.*">/https:\1/p' | sed -e 's/\r//g' | sed 's/[[:blank:]]//g')
curl -s "${USB_PACKAGE_URL}" --output /tmp/usbpackage.deb

DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "icaclient app_protection/install_app_protection select yes"
apt-get install -f /tmp/icaclient.deb
apt-get install -y --no-install-recommends /tmp/usbpackage.deb
