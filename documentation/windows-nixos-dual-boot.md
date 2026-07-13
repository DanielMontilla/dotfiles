# Windows + NixOS Dual Boot (loui) — Reference / North Star

Everything learned while getting loui (a NixOS machine) to dual-boot with Windows
and behave the way I want: pick Windows from the menu, and after a timeout boot
whatever I last selected.

If you ever redo this on a new machine, follow this file top to bottom.

---

## TL;DR

- loui boots with **systemd-boot**, not GRUB. ESP is mounted at `/boot`.
- Windows lives on a **separate ESP** from loui's. Its `bootmgfw.efi` is copied
  onto loui's ESP so systemd-boot can launch it.
- The menu auto-boots the **last-selected entry** (`default @saved`) after 15s.
- Rebuild with `./scripts/install loui` (a `nixos-rebuild switch --flake ".#loui"`).

---

## 1. Why systemd-boot and not GRUB

loui originally used GRUB (`boot.loader.grub` with `useOSProber = true`,
`default = "saved"`). That fails on loui:

- During `nixos-rebuild switch`, NixOS regenerates GRUB via `update-grub`, which
  runs **os-prober**.
- os-prober scans block devices and chokes on loui's `/dev/mapper/*` (LVM) devices
  (`lsblk: /dev/mapper/... not a block device`). It hangs.
- Because it hangs, the new generation's GRUB entry is **never written**, so it
  never appears in the boot menu and the `switch` unit stays "active"/hung.

systemd-boot does **not** run os-prober — it just copies entries — so the hang
disappears and every new generation shows up in the menu.

### `nixos/hosts/loui/bootloader.nix` (current)

```nix
{ config, pkgs, ... }:

{
  boot.loader = {
    timeout = 15;
    efi.canTouchEfiVariables = true;
    grub.enable = false;

    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      editor = false;
      extraInstallCommands = ''
        echo 'default @saved' >> /boot/loader/loader.conf

        echo 'title Windows' > /boot/loader/entries/windows.conf
        echo 'efi /EFI/Microsoft/Boot/bootmgfw.efi' >> /boot/loader/entries/windows.conf
      '';
    };
  };
}
```

---

## 2. `extraInstallCommands` runs in a sandbox — use only shell builtins

`extraInstallCommands` is executed while installing the bootloader, in an
environment where `PATH` does **not** contain `sed`, `cat`, `cp`, etc.

Symptom we hit: `sed: command not found`, `cat: command not found`,
`Failed to install bootloader`.

Fix: only use **shell builtins** (`echo`, `>`, `>>`, `read`, loops). No `sed`,
`cat`, `cp`, `awk`. That's why `default @saved` is *appended* (it wins as the
last `default` line) instead of being `sed`-edited in place.

`default @saved` → after the timeout, boot whatever entry was selected last
(including Windows). `timeout 15` comes from `boot.loader.timeout`.

---

## 3. Windows is on a SEPARATE ESP — copy its bootloader over

systemd-boot only sees its own ESP (`/boot`). Windows' EFI files are on a
different ESP, so a plain `efi /EFI/Microsoft/Boot/bootmgfw.efi` entry points at
a file that doesn't exist on loui's ESP → systemd-boot silently drops the entry
(it shows red "not reported" / "no such file or directory" in `bootctl list`).

Confirm: `ls /boot/EFI/` → only `BOOT`, `Linux`, `nixos`, `Nixos-boot`, `systemd`.
No `Microsoft`.

### Procedure (Windows ESP is never modified — we only read from it)

```bash
# 1. Find the Windows ESP (the vfat partition that is NOT /boot)
lsblk -f | grep -iE 'vfat|ntfs'

# 2. Mount it READ-ONLY (protects Windows)
sudo mkdir -p /mnt/win
sudo mount -o ro /dev/nvme0n1p1p1 /mnt/win     # use the device lsblk shows

# 3. Verify
ls /mnt/win/EFI/Microsoft/Boot/bootmgfw.efi

# 4. Copy onto loui's ESP (writes only to /boot)
sudo mkdir -p /boot/EFI/Microsoft/Boot
sudo cp -r /mnt/win/EFI/Microsoft/Boot/. /boot/EFI/Microsoft/Boot/

# 5. Unmount
sudo umount /mnt/win
```

Reboot → the **Windows** entry now resolves and boots. The copy persists across
`nixos-rebuild switch` (NixOS does not delete `/boot/EFI/Microsoft`).

> **BitLocker caveat:** if Windows uses TPM-backed BitLocker, booting the copied
> loader (now on loui's ESP instead of Windows' own ESP) changes the measured
> boot path and may ask for the **BitLocker recovery key**. It's recoverable.
> To avoid it entirely, use an XBOOTLDR setup (chainload Windows' *original*
> loader) instead of copying — see §6.

---

## 4. Rebuilding and the "stuck switch" trap

`scripts/install` does `sudo nixos-rebuild switch --flake ".#loui"`.

If a previous `switch` was interrupted, the transient unit
`nixos-rebuild-switch-to-configuration.service` can get stuck **active**, and
every later rebuild fails with:

```
Failed to start transient service unit: Unit nixos-rebuild-switch-to-configuration.service was already loaded or has a fragment file.
```

It's usually hung in os-prober / a dbus restart. Clear it (this is what worked):

```bash
systemctl status nixos-rebuild-switch-to-configuration.service   # confirm active (running)
sudo systemctl stop  nixos-rebuild-switch-to-configuration.service
sudo systemctl kill -s KILL nixos-rebuild-switch-to-configuration.service
sudo systemctl reset-failed
sudo systemctl daemon-reexec     # daemon-reload is NOT enough; reexec drops in-memory transient units
```

Then `./scripts/install loui` again. If a rebuild says `Could not acquire lock`,
the unit above is still active — kill it first (same steps).

### Verifying what's actually running

`/run/current-system` = what is **activated/running now**.
`/nix/var/nix/profiles/system` = the **default** generation (boot target).

```bash
readlink -f /run/current-system          # must match the loui store path
readlink -f /nix/var/nix/profiles/system # default generation
sudo nixos-rebuild list-generations
```

If these differ, activation never completed (see the stuck-switch steps above).

---

## 5. Other loui setup gotchas (so you don't repeat them)

- **`hardware-configuration.nix` must exist.** `nixos/hosts/loui/configuration.nix`
  imports `./hardware-configuration.nix`, but it is **not** in git by default
  (it's machine-specific). Generate it on the target machine:
  ```bash
  sudo nixos-generate-config --show-hardware-config > nixos/hosts/loui/hardware-configuration.nix
  ```
  A missing/untracked one makes the flake build fail with
  *"Path '.../hardware-configuration.nix' ... is not tracked by Git."*

- **Flake `inputs` must be in scope in modules.** Two things are required:
  1. `nixos/flake.nix` passes them: `specialArgs = { inherit inputs; };` inside
     the `loui` `nixosConfiguration`.
  2. The module that uses `inputs` must **declare it in its function signature**,
     e.g. `nixos/hosts/loui/packages.nix` starts with
     `{ config, pkgs, inputs, ... }:` — NOT just `{ config, pkgs, ... }:`.
     Without the `inputs` param, you get `undefined variable 'inputs'`.
     (framework's `packages.nix` declares it; that's why it worked there.)

- **"Git tree is dirty" warning is benign.** It just means uncommitted changes in
  `~/dotfiles`. Commit them (or ignore it) — it does not block the build.

- **`git` / `niri` "command not found" right after a rebuild:** your shell
  session predates the switch. Start a new shell (`exec bash`) or re-login.

- **Locale warnings (`es_VE.UTF-8`):** generated via
  `i18n.extraLocaleSettings` in `nixos/hosts/loui/user.nix` (mirrors framework).

---

## 6. Alternative to copying Windows (XBOOTLDR, no BitLocker risk)

Instead of copying `bootmgfw.efi`, mark the Windows ESP as an XBOOTLDR
partition so systemd-boot chainloads Windows' *original* loader (same path
Windows expects → no TPM/BitLocker prompt):

```nix
boot.loader.xbootldr = {
  enable = true;
  device = "/dev/disk/by-...";   # the Windows ESP device
};
```

This is more involved (needs the ESP mounted at the XBOOTLDR mountpoint and the
right device reference), so the copy in §3 is the faster route unless BitLocker
recovery becomes a problem.

---

## Quick command reference

```bash
# Rebuild loui
cd ~/dotfiles && ./scripts/install loui

# See what systemd-boot detects (incl. Windows entry status)
sudo bootctl list

# Find / verify the Windows ESP
lsblk -f | grep -iE 'vfat|ntfs'
ls /boot/EFI/                    # should it contain Microsoft? (it won't, until copied)

# Check running vs default generation
readlink -f /run/current-system
readlink -f /nix/var/nix/profiles/system

# Clear a stuck switch unit
sudo systemctl kill -s KILL nixos-rebuild-switch-to-configuration.service
sudo systemctl daemon-reexec
```
