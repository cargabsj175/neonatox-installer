# Neonatox Installer — TODO

Remaining features from `references.sh` (LFS bootstrap recipe) that a production installer should implement.

---

## Completed ✅

### Directory Layout
- ✅ **Explicit layout creation** — `lib/layout_lfs.sh` creates usr-merge structure
- ✅ **Multilib support** — `/usr/lib32` + `/lib32` symlink on x86_64
- ✅ **Virtual filesystem placeholders** — `/dev`, `/proc`, `/sys`, `/run` created
- ✅ **Package metadata** — `/var/nhopkg/{cache,files,logs,packages,repo}` added

### Essential Symlinks & Files
- ✅ **Dynamic linker symlinks** — `ld-linux-x86-64.so.2` and `ld-lsb-x86-64.so.3` in `/lib64`
- ✅ **Command symlinks** — `awk → gawk`, `sh → bash`
- ✅ **resolv.conf** — Configurable via `sysconfig set-resolv` (stub/static/none)
- ✅ **mtab** — Symlink to `/proc/self/mounts`

### System Identity
- ✅ **Automatic hostname generation** — DMI vendor/model + random suffix (`systemid set-auto`)
- ✅ **/etc/hosts** — Generated with localhost + hostname
- ✅ **/etc/machine-id** — Generated via openssl or boot_id

### Shell Configuration
- ✅ **/etc/inputrc** — Readline configuration
- ✅ **/etc/shells** — List valid shells
- ✅ **/etc/bashrc** — Aliases, PS1 prompt
- ✅ **/etc/profile** — Environment, path functions, XDG vars
- ✅ **/etc/profile.d/*.sh** — Modular scripts (extrapaths, readline, umask, i18n)
- ✅ **/etc/skel/** — `.bash_profile`, `.bashrc`, `.profile`

### Distribution Metadata
- ✅ **/etc/os-release** — Populate from state or defaults
- ✅ **/etc/lsb-release** — LSB compatibility

---

## Remaining TODO

### Users & Groups

- [ ] **System users/groups** — Currently only creates requested user + root; consider standard system accounts:
  - `messagebus`, `systemd-*`, `nobody`, `dhcpcd`, `ldap`
  - Groups: `wheel`, `users`, `input`, `video`, `audio`, `kvm`, etc.

### Enhancements

- [ ] **Multilib conditional** — Only create lib32 if target requires multilib (detect via package manager or config)
- [ ] **Timezone validation** — `timectl` should validate timezone exists in `/usr/share/zoneinfo`
- [ ] **Custom hostname** — Allow user to override auto-generated hostname via state
- [ ] **resolv.conf modes** — Add `copy-host` mode to copy from live system

### Testing

- [ ] **Automated verification** — Script to verify all files/symlinks exist post-install
- [ ] **Integration tests** — Test full install flow in VM
- [ ] **State recovery** — Test resume from partial install

### Documentation

- [ ] **Frontend examples** — CLI/TUI/GUI example implementations
- [ ] **Profile development guide** — How to create new distro profiles
- [ ] **State file specification** — Complete schema for all `.conf` files

---

## Priority

**High:**
- System users/groups (required for full system functionality)

**Medium:**
- Timezone validation
- Multilib conditional logic

**Low:**
- Documentation enhancements
- Automated testing infrastructure
