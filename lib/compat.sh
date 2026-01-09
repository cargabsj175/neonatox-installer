#!/bin/sh
# compat.sh - Compatibilidad BusyBox / GNU coreutils
# No contiene lógica de negocio

# --------------------------------------------------
# Utilidades básicas
# --------------------------------------------------

have() {
    command -v "$1" >/dev/null 2>&1
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

log() {
    echo "[*] $*"
}

# --------------------------------------------------
# Copia de árboles de directorios
# --------------------------------------------------
# Usa rsync si existe, fallback a cp -a
# --------------------------------------------------

copy_tree() {
    src="$1"
    dst="$2"

    [ -d "$src" ] || die "Origen no existe: $src"
    mkdir -p "$dst" || die "No se pudo crear $dst"

    if have rsync; then
        rsync -aHAX --numeric-ids "$src"/ "$dst"/
    else
        cp -a "$src"/. "$dst"/
    fi
}

# --------------------------------------------------
# Montaje seguro
# --------------------------------------------------

mount_if_needed() {
    dev="$1"
    mnt="$2"
    fstype="$3"

    mkdir -p "$mnt"

    if ! mountpoint -q "$mnt" 2>/dev/null; then
        if [ -n "$fstype" ]; then
            mount -t "$fstype" "$dev" "$mnt" \
                || die "No se pudo montar $dev en $mnt"
        else
            mount "$dev" "$mnt" \
                || die "No se pudo montar $dev en $mnt"
        fi
    fi
}

# --------------------------------------------------
# Hash de contraseña
# --------------------------------------------------

hash_pass() {
    pass="$1"

    if have openssl; then
        printf '%s' "$pass" | openssl passwd -6 -stdin
    else
        # Fallback (último recurso, depende del sistema)
        printf '%s' "$pass"
    fi
}
