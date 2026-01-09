#!/bin/sh
# state.sh - Estado común del instalador

STATE_BASE="${STATE_BASE:-/run/installer}"
STATE_DIR="$STATE_BASE/state"

# --------------------------------------------------
# Inicialización
# --------------------------------------------------

state_init() {
    mkdir -p "$STATE_DIR" || exit 1
}

# --------------------------------------------------
# Helpers
# --------------------------------------------------

_state_file() {
    echo "$STATE_DIR/$1.conf"
}

# --------------------------------------------------
# Escritura de estado
# --------------------------------------------------

state_set() {
    file="$1"
    key="$2"
    val="$3"

    conf="$(_state_file "$file")"
    tmp="$conf.tmp"

    mkdir -p "$STATE_DIR"

    # eliminar clave previa si existe
    if [ -f "$conf" ]; then
        grep -v "^$key=" "$conf" > "$tmp" || true
    else
        : > "$tmp"
    fi

    printf '%s=%s\n' "$key" "$val" >> "$tmp"
    mv "$tmp" "$conf"
}

# --------------------------------------------------
# Lectura de estado
# --------------------------------------------------

state_get() {
    file="$1"
    key="$2"
    conf="$(_state_file "$file")"

    [ -f "$conf" ] || return 1
    grep "^$key=" "$conf" | sed "s/^$key=//"
}

state_load() {
    file="$1"
    conf="$(_state_file "$file")"

    [ -f "$conf" ] || return 1
    # shellcheck disable=SC1090
    . "$conf"
}

# --------------------------------------------------
# Validación
# --------------------------------------------------

state_ok() {
    touch "$STATE_DIR/$1.ok"
}

state_require() {
    file="$1"
    [ -f "$STATE_DIR/$file.ok" ] || {
        echo "Estado requerido no completado: $file" >&2
        exit 1
    }
}
