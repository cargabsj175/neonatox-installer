# Neonatox Installer

> Instalador universal, modular y portable basado en estados, diseñado para sistemas live generados con **neonatox-live-boot**.

---

## 1. Filosofía general

El instalador **no es un script monolítico**, sino un **conjunto de micro-herramientas** que:

- Funcionan de forma independiente
- Guardan estado en archivos `.conf` + `.ok`
- Pueden ser llamadas desde CLI, TUI o GUI
- No dependen de systemd
- Son compatibles con BusyBox

El frontend **no decide nada**, solo invoca micro-apps.

---

## 2. Modelo de estados

Todos los pasos del instalador usan un sistema de estados persistentes:

```
/run/installer/state/
  disk.conf / disk.ok
  locale.conf / locale.ok
  time.conf / time.ok
  user.conf / user.ok
  fstab.conf / fstab.ok
  install.conf / install.ok
```

### Reglas

- Un `.conf` guarda valores
- Un `.ok` indica que el paso está completo
- `installctl` **solo aplica**, nunca pregunta

---

## 3. Micro-aplicaciones

### 3.1 `partctl`

**Responsabilidad:** definir particiones (no formatear)

Comandos:

```
partctl set-root /dev/sda2 ext4
partctl set-boot /dev/sda1 vfat
partctl set-swap /dev/sda3
partctl finalize
```

Produce:
- `disk.conf`
- `fstab.conf`

---

### 3.2 `localectl` (propio)

**Responsabilidad:** idioma y teclado TTY

Archivos escritos en el sistema destino:

- `/etc/locale.conf`
- `/etc/vconsole.conf`

Comandos:

```
localectl set-lang es_ES.UTF-8
localectl set-keymap latam
localectl apply /mnt/target
```

No usa `localectl` de systemd.

---

### 3.3 `timectl` (propio)

**Responsabilidad:** zona horaria

Archivos:

- `/etc/localtime` (symlink)
- `/etc/timezone`

Comandos:

```
timectl set-timezone America/Sao_Paulo
timectl apply /mnt/target
```

---

### 3.4 `usersctl`

**Responsabilidad:** usuarios y contraseñas

Características clave:

- Nunca genera hashes fuera del sistema instalado
- Usa `chroot + chpasswd`
- Compatible con PAM/systemd

Comandos:

```
usersctl create usuario
usersctl rootpass
usersctl apply /mnt/target
```

---

### 3.5 `fstabctl`

**Responsabilidad:** generar `/etc/fstab`

Basado únicamente en estado (`fstab.conf`).

```
fstabctl generate /mnt/target
```

---

### 3.6 `bootctl`

**Responsabilidad:** kernel, initrd y bootloader

Funciones:

- Generar initrd según perfil
- Copiar y renombrar `vmlinuz`
- Instalar GRUB **en el disco** (`/dev/sdX`)

#### Caso especial: Neonatox

- `mkinitramfs` **solo funciona en el live**
- Se hace `--bind` del `/boot` del target sobre `/boot` del live
- Se genera el initrd
- Se desmonta `/boot`
- Se copia `vmlinuz` del live al target
- Se renombra usando el sufijo del initrd si coincide `uname -r` y `uname -m`

---

## 4. `installctl` – Flujo principal

Orden exacto de ejecución:

1. Cargar estados requeridos
2. Detectar y montar `rootfs.squashfs`
3. Montar partición root destino
4. Crear layout (`usr-merge` o legacy)
5. Copiar rootfs live
6. Aplicar `localectl`
7. Aplicar `timectl`
8. Montar `/dev /proc /sys /run`
9. Ejecutar `profile_*_postinstall`
10. Aplicar `usersctl`
11. Generar `fstab`
12. Ejecutar `bootctl`

---

## 5. Perfiles de distribución

Los perfiles **no instalan**, solo adaptan.

Interfaz esperada:

```sh
profile_<name>_postinstall()
profile_<name>_mkinitrd()
```

### Detección

Basada en `/etc/os-release` del sistema instalado.

### Initramfs por distro

- Debian / Ubuntu → `update-initramfs`
- Arch → `mkinitcpio`
- Alpine → `mkinitfs`
- RedHat / Fedora → `dracut`
- Neonatox → método live + bind `/boot`

---

## 6. Reglas importantes

### 6.1 `chroot` + detección de comandos

Nunca usar:

```sh
chroot "$TARGET" command -v foo
```

Siempre usar:

```sh
chroot "$TARGET" sh -c "command -v foo"
```

Motivo: `command` es builtin del shell.

---

## 7. Garantías del live (neonatox-live-boot)

Una ISO generada con neonatox-live-boot garantiza:

- rootfs completo
- módulos del kernel presentes
- toolchain de initramfs intacta
- apta para generar initrd en chroot

(No se hacen optimizaciones agresivas.)

---

## 8. Estado actual del proyecto

- Núcleo funcional y probado
- Instalación completa verificada
- Login de usuario correcto
- Arquitectura cerrada

Siguientes pasos:

- Wizard CLI / TUI / GTK
- Documentación pública
- Pulido UX

---

**Neonatox Installer** no es un script: es un framework de instalación portable.

