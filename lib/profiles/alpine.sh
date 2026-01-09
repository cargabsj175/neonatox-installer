#!/bin/sh
# Perfil Alpine Linux

profile_alpine_postinstall() {
    MOUNT_ROOT="$1"
    echo "[*] Ajustes post-instalación Alpine"

    # Asegurar hostname
    if [ -f "$MOUNT_ROOT/etc/hostname" ]; then
        :
    else
        echo "alpine" > "$MOUNT_ROOT/etc/hostname"
    fi

    # OpenRC necesita esto
    if [ -d "$MOUNT_ROOT/etc/runlevels" ]; then
        mkdir -p "$MOUNT_ROOT/run/openrc"
        touch "$MOUNT_ROOT/run/openrc/softlevel"
    fi
}
