#!/bin/sh
# layout_lfs.sh - Layout base tipo LFS

layout_lfs() {
    LFS="$1"

    [ -n "$LFS" ] || {
        echo "layout_lfs: ruta no definida" >&2
        return 1
    }

    echo "[*] Creando layout LFS en $LFS"

    # Base
    mkdir -p "$LFS"/{etc,var} "$LFS"/usr/{bin,lib,sbin}

    for i in bin lib sbin; do
        if [ ! -e "$LFS/$i" ]; then
            ln -sv "usr/$i" "$LFS/$i"
        fi
    done

    case "$(uname -m)" in
        x86_64)
            mkdir -p "$LFS/lib64"
            ;;
    esac

    # Multilib
    mkdir -p "$LFS/usr/lib32"
    
    if [ ! -e "$LFS/lib32" ]; then
        ln -sv usr/lib32 "$LFS/lib32"
    fi

    # Virtual kernel filesystems
    mkdir -p "$LFS"/{dev,proc,sys,run}

    # Estructura general
    mkdir -p "$LFS"/{boot,home,mnt,opt,srv}

    mkdir -p "$LFS"/etc/{opt,sysconfig}
    mkdir -p "$LFS"/lib/firmware
    mkdir -p "$LFS"/media/{floppy,cdrom}

    mkdir -p "$LFS"/usr/{,local/}{include,src}
    mkdir -p "$LFS"/usr/lib/locale
    mkdir -p "$LFS"/usr/local/{bin,lib,sbin}

    mkdir -p "$LFS"/usr/{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -p "$LFS"/usr/{,local/}share/{misc,terminfo,zoneinfo}

    for i in 1 2 3 4 5 6 7 8; do
        mkdir -p "$LFS"/usr/{,local/}share/man/man$i
    done

    mkdir -p "$LFS"/var/{cache,local,log,mail,opt,spool}
    mkdir -p "$LFS"/var/lib/{color,misc,locate}

    # Symlinks runtime
    rm -rf "$LFS/var/run" "$LFS/var/lock"
    ln -sf /run "$LFS/var/run"
    ln -sf /run/lock "$LFS/var/lock"

    # Permisos especiales
    install -dv -m 0750 "$LFS/root"
    install -dv -m 1777 "$LFS/tmp" "$LFS/var/tmp"
}
