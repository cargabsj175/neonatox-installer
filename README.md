[![License: GPLv3+](https://img.shields.io/badge/license-GPLv3%2B-blue.svg)](LICENSE)[![Language: Bash](https://img.shields.io/badge/language-Bash-green.svg)](https://www.gnu.org/software/bash/)[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/cargabsj175/neonatox-installer)

# Neonatox Installer

> Universal, modular, and portable state-based installer framework designed for live systems generated with **neonatox-live-boot**.

---

## 1. Overview

The installer is **not a monolithic script**, but a **set of micro-applications** that:

- Work independently
- Store state in `.conf` + `.ok` files
- Can be called from CLI, TUI, or GUI
- Do not depend on systemd
- Are BusyBox-compatible

The frontend **makes no decisions**, it only invokes micro-apps.

---

## 2. State Model

All installer steps use a persistent state system:

```
/run/installer/state/
  disk.conf / disk.ok
  locale.conf / locale.ok
  time.conf / time.ok
  user.conf / user.ok
  fstab.conf / fstab.ok
  install.conf / install.ok
  systemid.conf / systemid.ok
  sysconfig.conf / sysconfig.ok
  distro.conf / distro.ok
```

### Rules

- `.conf` stores values
- `.ok` indicates step is complete
- `installctl` **only applies**, never asks

---

## 3. Micro-applications

### 3.1 `partctl`

**Responsibility:** Define partitions (not format)

Commands:

```
partctl set-root /dev/sda2 ext4
partctl set-boot /dev/sda1 vfat
partctl set-swap /dev/sda3
partctl finalize
```

Produces:
- `disk.conf`
- `fstab.conf`

---

### 3.2 `localectl` (custom)

**Responsibility:** Locale and TTY keyboard

Files written to target system:

- `/etc/locale.conf`
- `/etc/vconsole.conf`

Commands:

```
localectl set-lang es_ES.UTF-8
localectl set-keymap latam
localectl apply /mnt/target
```

Does not use systemd's `localectl`.

---

### 3.3 `timectl` (custom)

**Responsibility:** Timezone

Files:

- `/etc/localtime` (symlink)
- `/etc/timezone`

Commands:

```
timectl set-timezone America/Sao_Paulo
timectl apply /mnt/target
```

---

### 3.4 `usersctl`

**Responsibility:** Users and passwords

Key features:

- Never generates hashes outside the installed system
- Uses `chroot + chpasswd`
- PAM/systemd compatible

Commands:

```
usersctl create username password
usersctl rootpass password
usersctl apply /mnt/target
```

---

### 3.5 `fstabctl`

**Responsibility:** Generate `/etc/fstab`

Based solely on state (`fstab.conf`).

```
fstabctl generate /mnt/target
```

---

### 3.6 `bootctl`

**Responsibility:** Kernel, initrd, and bootloader

Functions:

- Generate initrd per profile
- Copy and rename `vmlinuz`
- Install GRUB **to disk** (`/dev/sdX`)

#### Special case: Neonatox

- `mkinitramfs` **only works in the live environment**
- Bind-mount `/boot` from target to live
- Generate initrd
- Unmount `/boot`
- Copy `vmlinuz` from live to target
- Rename using initrd suffix if `uname -r` and `uname -m` match

---

### 3.7 `systemid`

**Responsibility:** System identity (hostname, hosts, machine-id)

Commands:

```
systemid set-hostname myhost
systemid set-auto              # Auto-generate from DMI
systemid apply /mnt/target
```

Files:

- `/etc/hostname`
- `/etc/hosts`
- `/etc/machine-id`

---

### 3.8 `sysconfig`

**Responsibility:** Essential system configuration

Commands:

```
sysconfig set-resolv stub      # stub|static|none
sysconfig apply /mnt/target
```

Files:

- `/etc/resolv.conf` (configurable mode)
- `/etc/mtab` → `/proc/self/mounts`
- `/etc/shells`
- `/etc/inputrc`
- Symlinks: `awk` → `gawk`, `sh` → `bash`

---

### 3.9 `shellconfig`

**Responsibility:** Shell environment configuration

Commands:

```
shellconfig apply /mnt/target
```

Files:

- `/etc/bashrc` (aliases, PS1)
- `/etc/profile` (environment, PATH functions)
- `/etc/profile.d/*.sh` (extrapaths, readline, umask, i18n)
- `/etc/skel/` (`.bash_profile`, `.bashrc`, `.profile`)

---

### 3.10 `distroinfo`

**Responsibility:** Distribution metadata

Commands:

```
distroinfo set "GNU NeonatoX" "2026" "NeonatoX" "Mapoyo"
distroinfo apply /mnt/target
```

Files:

- `/etc/os-release`
- `/etc/lsb-release`

---

## 4. `installctl` – Main Flow

Exact execution order:

1. Load required states
2. Detect and mount `rootfs.squashfs`
3. Mount target root partition
4. Create layout (usr-merge or legacy)
5. Copy live rootfs
6. Apply `localectl`
7. Apply `timectl`
8. Apply `systemid` (hostname, hosts, machine-id)
9. Apply `sysconfig` (symlinks, shells, inputrc)
10. Apply `shellconfig` (bashrc, profile, profile.d, skel)
11. Apply `distroinfo` (os-release, lsb-release)
12. Mount `/dev /proc /sys /run`
13. Run `profile_*_postinstall`
14. Apply `usersctl`
15. Generate fstab
16. Run `bootctl`

---

## 5. Distribution Profiles

Profiles **do not install**, they only adapt.

Expected interface:

```sh
profile_<name>_postinstall()
profile_<name>_mkinitrd()
```

### Detection

Based on `/etc/os-release` of the installed system.

### Initramfs by distro

- Debian / Ubuntu → `update-initramfs`, `locale-gen`
- Arch → `mkinitcpio`
- Alpine → `mkinitfs`
- RedHat / Fedora → `dracut`
- LFS → custom layout
- Neonatox → live + bind `/boot`

---

## 6. Important Rules

### 6.1 `chroot` + command detection

Never use:

```sh
chroot "$TARGET" command -v foo
```

Always use:

```sh
chroot "$TARGET" sh -c "command -v foo"
```

Reason: `command` is a shell builtin.

### 6.2 Never apply on live root

Tools like `systemid`, `sysconfig`, `shellconfig`, `usersctl` must never target `/` — always a mounted target root.

---

## 7. Live Guarantees (neonatox-live-boot)

An ISO generated with neonatox-live-boot guarantees:

- Complete rootfs
- Kernel modules present
- Intact initramfs toolchain
- Suitable for generating initrd in chroot

(No aggressive optimizations are made.)

---

## 8. Project Status

### Completed

- Core functional and tested
- Full installation verified
- User login working
- Architecture finalized
- System identity and configuration micro-apps implemented

### Micro-apps Implemented

| Tool | Status |
|------|--------|
| `partctl` | ✅ Complete |
| `localectl` | ✅ Complete |
| `timectl` | ✅ Complete |
| `usersctl` | ✅ Complete |
| `fstabctl` | ✅ Complete |
| `bootctl` | ✅ Complete |
| `systemid` | ✅ Complete |
| `sysconfig` | ✅ Complete |
| `shellconfig` | ✅ Complete |
| `distroinfo` | ✅ Complete |

### Next Steps

- CLI / TUI / GTK wizard frontends
- Public documentation
- UX polish
- System users/groups (messagebus, systemd-*, etc.)

---

**Neonatox Installer** is not a script: it is a portable installation framework.
