# Implementación — Características desde references.sh

Este documento detalla cada característica implementada en el instalador, basada en la receta LFS de `references.sh`.

---

## 1. systemid — Identidad del Sistema

**Archivo:** `bin/systemid`

**Propósito:** Generar y aplicar hostname, /etc/hosts, y machine-id.

### Comandos

```sh
systemid set-hostname NAME     # definir hostname manualmente
systemid set-auto              # auto-generar desde DMI board vendor/model
systemid apply MOUNT_ROOT      # aplicar en sistema destino
```

### Estado

- `systemid.conf`: `HOSTNAME=<name>`, `HOSTNAME_AUTO=1`
- `systemid.ok`: indica completado

### Archivos generados

| Archivo | Descripción |
|---------|-------------|
| `/etc/hostname` | Nombre del host |
| `/etc/hosts` | 127.0.0.1 + ::1 con hostname |
| `/etc/machine-id` | UUID único (openssl o boot_id) |

### Auto-generación de hostname

El hostname se genera con formato: `<vendor>-<model>-<random>`

- `vendor`: board_vendor (6 chars, lowercase, alphanumeric + `-`)
- `model`: board_name (6 chars, lowercase, alphanumeric + `-`)
- `random`: 4 hex digits from `/dev/urandom`

Fallback: `neonatox-<random>`

### machine-id

Generación prioritaria:
1. `openssl rand -hex 16`
2. `/proc/sys/kernel/random/boot_id` (sin guiones)
3. Fallback: timestamp hex

---

## 2. sysconfig — Configuración Esencial

**Archivo:** `bin/sysconfig`

**Propósito:** Symlinks esenciales, /etc/shells, /etc/inputrc, resolv.conf.

### Comandos

```sh
sysconfig set-resolv MODE      # stub|static|none
sysconfig apply MOUNT_ROOT     # aplicar configuración
```

### Estado

- `sysconfig.conf`: `RESOLV_MODE=<mode>`
- `sysconfig.ok`: indica completado

### Modos resolv.conf

| Modo | Comportamiento |
|------|----------------|
| `stub` | Symlink a systemd-resolve o DNS estático (8.8.8.8) |
| `static` | DNS estático (8.8.8.8, 8.8.4.4) |
| `none` | No crear resolv.conf |

### Symlinks creados (si no existen)

| Symlink | Destino | Condición |
|---------|---------|-----------|
| `/etc/mtab` | `/proc/self/mounts` | Siempre |
| `/etc/resolv.conf` | `stub-resolv.conf` o archivo | Si no existe |
| `/usr/bin/awk` | `gawk` | Si gawk existe |
| `/usr/bin/sh` | `bash` | Si bash existe |
| `/lib64/ld-linux-x86-64.so.2` | `../lib/ld-linux-x86-64.so.2` | x86_64 |
| `/lib64/ld-lsb-x86-64.so.3` | `../lib/ld-linux-x86-64.so.2` | x86_64 |

### Archivos creados

- `/etc/shells` — `/bin/sh`, `/bin/bash`
- `/etc/inputrc` — Readline config (colores, keybindings)

---

## 3. shellconfig — Configuración de Shells

**Archivo:** `bin/shellconfig`

**Propósito:** /etc/bashrc, /etc/profile, /etc/profile.d/, /etc/skel/

### Comandos

```sh
shellconfig apply MOUNT_ROOT
```

### Archivos generados

#### /etc/bashrc
- Aliases: `ls --color=auto`, `grep --color=auto`
- PS1 con colores (root: rojo, user: verde)

#### /etc/profile
- Funciones: `pathremove`, `pathprepend`, `pathappend`
- PATH inicial: `/usr/bin` (+ `/usr/sbin` para root)
- HISTSIZE, HISTIGNORE
- XDG vars: `XDG_DATA_DIRS`, `XDG_CONFIG_DIRS`, `XDG_RUNTIME_DIR`
- Source de `/etc/profile.d/*.sh`

#### /etc/profile.d/

| Script | Propósito |
|--------|-----------|
| `extrapaths.sh` | /usr/local paths, PKG_CONFIG_PATH |
| `readline.sh` | INPUTRC default |
| `umask.sh` | 002 (user), 022 (root) |
| `i18n.sh` | Locale export desde /etc/locale.conf |

#### /etc/skel/

| Archivo | Propósito |
|---------|-----------|
| `.bash_profile` | Source .bashrc, prepend ~/bin |
| `.bashrc` | Source /etc/bashrc |
| `.profile` | Prepend ~/bin |

---

## 4. distroinfo — Metadata de Distribución

**Archivo:** `bin/distroinfo`

**Propósito:** /etc/os-release, /etc/lsb-release

### Comandos

```sh
distroinfo set NAME VERSION ID CODENAME
distroinfo apply MOUNT_ROOT
```

### Estado

- `distro.conf`: `NAME`, `VERSION`, `ID`, `CODENAME`
- `distro.ok`: indica completado

### Archivos generados

#### /etc/os-release
```sh
NAME="GNU NeonatoX"
VERSION="2026"
ID="NeonatoX"
PRETTY_NAME="GNU NeonatoX 2026"
VERSION_CODENAME="Mapoyo"
```

#### /etc/lsb-release
```sh
DISTRIB_ID="NeonatoX"
DISTRIB_RELEASE="2026"
DISTRIB_CODENAME="Mapoyo"
DISTRIB_DESCRIPTION="GNU NeonatoX"
```

### Valores por defecto

| Variable | Default |
|----------|---------|
| NAME | GNU NeonatoX |
| VERSION | 2026 |
| ID | NeonatoX |
| CODENAME | Mapoyo |

---

## 5. layout_lfs — Paquete de Metadata (nhopkg)

**Archivo modificado:** `lib/layout_lfs.sh`

**Propósito:** Crear directorios para el gestor de paquetes nhopkg.

### Directorios creados

```
/var/nhopkg/
  cache/
  files/
  logs/
  packages/
  repo/
```

---

## 6. installctl — Flujo Actualizado

**Archivo modificado:** `bin/installctl`

### Nuevos pasos en el flujo

Después de `timectl`:

```
7. systemid apply    (hostname, hosts, machine-id)
8. sysconfig apply   (symlinks, shells, inputrc)
9. shellconfig apply (bashrc, profile, profile.d, skel)
10. distroinfo apply (os-release, lsb-release)
11. profile_*_postinstall
12. usersctl apply
13. fstabctl generate
14. bootctl install
```

### Estados requeridos

| Paso | Estado | Opcional |
|------|--------|----------|
| systemid | `systemid.ok` | Sí (se aplica si existe) |
| sysconfig | `sysconfig.ok` | No (siempre se aplica) |
| shellconfig | — | No (siempre se aplica) |
| distroinfo | `distro.ok` | Sí (usa defaults si no existe) |

---

## 7. debian.sh — Perfil Actualizado

**Archivo modificado:** `lib/profiles/debian.sh`

**Cambio:** Removida lógica redundante de hostname (ahora cubierto por `systemid`).

---

## Seguridad y Validaciones

### Protección contra live root

Todas las micro-apps validan:
```sh
[ "$TARGET" != "/" ] || die "Nunca aplicar sobre / (live)"
```

### Permisos

- `/etc/shadow`: 600
- `/etc/passwd`, `/etc/group`: 644
- `/etc/profile.d/*.sh`: +x
- `/root`: 0750
- `/tmp`, `/var/tmp`: 1777

---

## Próximos Pasos (ver TODO.md)

- [ ] System users/groups (messagebus, systemd-*, etc.)
- [ ] Group memberships (wheel, audio, video, etc.)
- [ ] Multilib layout condicional (solo si requiere)
- [ ] Validación de zonas horarias en timectl
- [ ] Soporte para hostname personalizado en estado
