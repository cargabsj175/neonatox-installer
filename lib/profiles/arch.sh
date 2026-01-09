#!/bin/sh
# Perfil Arch Linux

profile_arch_postinstall() {
    MOUNT_ROOT="$1"
    echo "[*] Ajustes post-instalación Arch Linux"

    if chroot "$MOUNT_ROOT" sh -c "command -v pacman-key" >/dev/null 2>&1; then
        chroot "$MOUNT_ROOT" pacman-key --init
        chroot "$MOUNT_ROOT" pacman-key --populate archlinux
    fi
}
