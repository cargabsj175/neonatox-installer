#!/bin/sh
# Perfil RedHat / Fedora

profile_redhat_postinstall() {
    MOUNT_ROOT="$1"
    echo "[*] Ajustes post-instalación RedHat/Fedora"

    # Hostname por defecto
    if [ -f "$MOUNT_ROOT/etc/hostname" ]; then
        :
    else
        echo "localhost.localdomain" > "$MOUNT_ROOT/etc/hostname"
    fi

    # SELinux puede romper installs live → desactivar si existe
    if [ -f "$MOUNT_ROOT/etc/selinux/config" ]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' \
            "$MOUNT_ROOT/etc/selinux/config" 2>/dev/null || true
    fi

    # GRUB2
    if chroot "$MOUNT_ROOT" sh -c "command -v grub2-mkconfig" >/dev/null 2>&1; then
        chroot "$MOUNT_ROOT" grub2-mkconfig -o /boot/grub2/grub.cfg || true
    fi
}
