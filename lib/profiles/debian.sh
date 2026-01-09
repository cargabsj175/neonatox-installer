#!/bin/sh
# Perfil Debian / Ubuntu

profile_debian_postinstall() {
    MOUNT_ROOT="$1"
    echo "[*] Ajustes post-instalación Debian/Ubuntu"

    # Asegurar hostname
    if [ -f "$MOUNT_ROOT/etc/hostname" ]; then
        :
    else
        echo "debian" > "$MOUNT_ROOT/etc/hostname"
    fi

    # Regenerar locales si existe la herramienta
    if chroot "$MOUNT_ROOT" sh -c "command -v locale-gen" >/dev/null 2>&1; then
        chroot "$MOUNT_ROOT" locale-gen || true
    fi

    # GRUB (solo si está instalado)
    if chroot "$MOUNT_ROOT" sh -c "command -v update-grub" >/dev/null 2>&1; then
        chroot "$MOUNT_ROOT" update-grub || true
    fi
}
