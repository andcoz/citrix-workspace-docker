# syntax=docker/dockerfile:1
#
# Citrix Workspace App for Linux + Zoom VDI Citrix Plugin
#
# This mirrors the logic from the ca.dcloud.ICAClient Flatpak manifest and the
# AUR zoom-citrix-plugin PKGBUILD, but installs as root inside the container
# instead of a sandboxed Flatpak user. That's the whole point of this image:
# the Flatpak install.sh explicitly skips USB support and App Protection
# because those require running the Citrix installer as root. Here, we ARE
# root, so we enable them.
#
# Since this is an Ubuntu base image, the Zoom VDI plugin is installed from
# Zoom's native .deb via apt, rather than extracting the CentOS rpm with
# rpm2cpio/cpio the way the Flatpak (targeting a generic runtime) and the
# AUR package (targeting Arch) had to.

FROM ubuntu:24.04

LABEL maintainer="info@matolcsi.me"
LABEL description="Citrix Workspace App for Linux with Zoom VDI plugin, USB redirection and App Protection enabled"
SHELL ["/bin/bash", "-c"]
ARG ICACLIENT_URL=""
ARG EPAPLUGIN_URL=""
ARG myID=""
ARG ZOOM_PLUGIN_URL="https://zoom.us/download/vdi/7.0.11.27050/zoomvdi-universal-plugin-ubuntu_7.0.11.deb"
# No published checksum found for the Ubuntu .deb (only the CentOS rpm had
# one in the Flatpak manifest). The build prints the computed sha512 to the
# build log -- copy it in here on your next build to pin it for reproducibility.
ARG ZOOM_PLUGIN_SHA512="0e5d48b4aa08fbc502be34f191aab6195cb272bf5930e1957f137ec34783ed1aea541364eccd5cb061a671d113fe28c1acfe9303ca00fa2bca139136eea52c43"
ARG ICAROOT=/opt/Citrix/ICAClient

ENV ICAROOT=${ICAROOT} \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# Base dependencies of Citrix/Zoom
# ---------------------------------------------------------------------------

RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        curl \
        gnupg \
        build-essential \
        tar \
        sudo \
        procps \
        psmisc \
        usbutils \
        dbus-x11 \
        locales \
        dnsutils \
        libcap2 \
        libc++1-18 \
        libcanberra-gtk3-module \
        libidn12 \
        libmotif-common \
        libopengl0 \
        libspeexdsp1 \
        libpng16-16t64 \
        libxaw7 \
        libxcb-keysyms1 \
        libxcb-shape0 \
        libxpm4 \
        libxft2 \
        libxss1 \
        libxtst6 \
        libxv1 \
        libnss3 \
        libopenjp2-7 \
        libpcsclite1 \
        libpulse0 \
        libsoup-2.4 \
        libgtk-3-0 \
        libva2 \
        libva-x11-2 \
        libva-drm2 \
        libwebkit2gtk-4.1-0 \
        libxcb1 \
        libxcb-util1 \
        libxcb-cursor0 \
        libxcb-render-util0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render0 \
        libxcb-shape0 \
        libxcb-shm0 \
        libxcb-sync1 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libxcb-xtest0 \
        libxcb-xkb1 \
        libx11-xcb1 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        x11-utils \
        gtk2-engines-pixbuf \
        ibus \
        pcscd \
        udev \
        net-tools \
        python3 \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Fetch and install Citrix Workspace App for Linux
# ---------------------------------------------------------------------------
# Citrix's download link is dynamic and gated behind their downloads page, so
# (like the Flatpak manifest) we scrape it at build time unless a direct
# ICACLIENT_URL build-arg is supplied. If Citrix changes their EULA/click-through
# flow this scrape can break -- if it does, download the icaclient.*amd64.deb
# yourself and pass --build-arg ICACLIENT_URL=file:///... or a direct URL.
COPY install_citrix.sh /tmp/install_citrix.sh
RUN chmod +x /tmp/install_citrix.sh && /tmp/install_citrix.sh


# Trust the system CA bundle inside Citrix's own keystore.
RUN ln -sf /etc/ssl/certs/*.pem "${ICAROOT}/keystore/cacerts/" 2>/dev/null || true; \
    "${ICAROOT}/util/ctx_rehash" "${ICAROOT}/keystore/cacerts/" || true

# ---------------------------------------------------------------------------
# Fetch and install Citrix EPA Plug In for Linux
# ---------------------------------------------------------------------------
# Citrix's download link is dynamic anad gated behind their downloads page, so
# (like the Flatpak manifest) we scrape it at build time unless a direct
# EPAPLUGIN_URL build-arg is supplied. If Citrix changes their EULA/click-through
# flow this scrape can break -- if it does, download the nsepa*.deb
# yourself and pass --build-arg EPAPLUGIN_URL=file:///... or a direct URL.
COPY install_citrix.sh /tmp/install_epa.sh
RUN chmod +x /tmp/install_epa.sh && /tmp/install_epa.sh


# ---------------------------------------------------------------------------
# Zoom VDI Citrix Plugin
# ---------------------------------------------------------------------------

RUN set -eux; \
    wget -q "${ZOOM_PLUGIN_URL}" -O /tmp/zoomvdi-universal-plugin-ubuntu.deb; \
    COMPUTED_SHA512=$(sha512sum /tmp/zoomvdi-universal-plugin-ubuntu.deb | awk '{print $1}'); \
    echo "Zoom plugin .deb sha512: ${COMPUTED_SHA512}"; \
    if [ -n "${ZOOM_PLUGIN_SHA512}" ]; then \
        echo "${ZOOM_PLUGIN_SHA512}  /tmp/zoomvdi-universal-plugin-ubuntu.deb" | sha512sum -c -; \
    else \
        echo "WARNING: ZOOM_PLUGIN_SHA512 not set, skipping checksum verification. Pin it using the hash printed above."; \
    fi; \
    apt-get install -y /tmp/zoomvdi-universal-plugin-ubuntu.deb; \
    rm -rf /var/lib/apt/lists/*;


# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
RUN rm -rf /tmp/icaclient.deb /tmp/usbpackage.deb


COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN EXISTING_USER=$(getent passwd ${myID} | cut -d: -f1) \
 && if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "citrixuser" ]; then \
      usermod -l citrixuser -d /home/citrixuser -m "$EXISTING_USER" \
      && groupmod -n citrixuser "$EXISTING_USER" 2>/dev/null || true; \
    elif ! id citrixuser >/dev/null 2>&1; then \
      groupadd -g 1000 citrixuser \
      && useradd -m -u ${myID} -g 1000 -s /bin/bash citrixuser; \
    fi

RUN mkdir -p /home/citrixuser/.ICAClient && \
    chown -R citrixuser:citrixuser /home/citrixuser

WORKDIR /home/citrixuser
ENV HOME=/home/citrixuser

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
