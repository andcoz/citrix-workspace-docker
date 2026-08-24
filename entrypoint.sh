#!/bin/bash

set -e

ICAROOT="${ICAROOT:-/opt/Citrix/ICAClient}"

# Clear a stale temp dir left over from an unclean shutdown, which otherwise
# hangs the next launch.
if [ -d "$HOME/.ICAClient/.tmp" ]; then
    rm -rf "$HOME/.ICAClient/.tmp"
fi

# Start Citrix's logging service.
"${ICAROOT}/util/ctxcwalogd" &

if [ -x "${ICAROOT}/ctxappprotectiond" ]; then
    "${ICAROOT}/ctxappprotectiond" &
fi



# --- PulseAudio user match -----------------------------------------------
# The container runs as root by default, but the host's PulseAudio socket at
# /run/user/$myID/pulse is bound to $myID with cookie-based auth. Citrix
# logs this as "PulseAudio context failed: Connection refused" when the
# connecting UID doesn't match. Fix: run the actual Citrix session as the
# matching $myID (citrixuser, created in the Dockerfile with -u $myID), while
# the daemons above stay root since they need real privileges - eg. for app protection
CITRIX_USER="${CITRIX_USER:-citrixuser}"
CITRIX_HOME="$(getent passwd "$CITRIX_USER" | cut -d: -f6)"
CITRIX_UID="$(id -u "$CITRIX_USER")"
CITRIX_GID="$(id -g "$CITRIX_USER")"

export HOME="$CITRIX_HOME"
export PULSE_SERVER="${PULSE_SERVER:-unix:/run/user/$CITRIX_UID/pulse/native}"
export GTK_MODULES=
export QT_QPA_PLATFORM=xcb
if [ -f /run/user/$CITRIX_UID/pulse/cookie ]; then
    export PULSE_COOKIE=/run/user/$CITRIX_UID/pulse/cookie
fi

cleanup() {
    pkill --signal 9 -f UtilDaemon 2>/dev/null || true
    for process in ctxappprotectiond AuthManagerDaem ServiceRecord ctxcwalogd icasessionmgr; do
        pkill -f "$process" 2>/dev/null || true
    done
}
trap cleanup EXIT

# Launch the provided .ica file, or fall back to the Workspace self-service
# dashboard if none was given. Dropped to $CITRIX_USER (matching the host's
# PulseAudio-owning UID) via `su`, carrying through the env vars it needs.
# Not using `exec` here so the cleanup trap above still fires once this exits.
if id "$CITRIX_USER" >/dev/null 2>&1; then
    RUN_AS="su $CITRIX_USER -s /bin/bash -c"
else
    echo "WARNING: user '$CITRIX_USER' not found, falling back to root (PulseAudio will likely fail)"
    RUN_AS="bash -c"
fi

if [ $# -ne 0 ]; then
    echo "Launching with icafile: $1"
    $RUN_AS "ICAROOT='$ICAROOT' PULSE_SERVER='$PULSE_SERVER' PULSE_COOKIE='$PULSE_COOKIE' DISPLAY='$DISPLAY' XAUTHORITY='$XAUTHORITY' '${ICAROOT}/wfica.sh' '$1'"
else
    $RUN_AS "ICAROOT='$ICAROOT' PULSE_SERVER='$PULSE_SERVER' PULSE_COOKIE='$PULSE_COOKIE' DISPLAY='$DISPLAY' XAUTHORITY='$XAUTHORITY' '${ICAROOT}/selfservice'"
fi
