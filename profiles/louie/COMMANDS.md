# louie — Useful Commands

## Install / rebuild

```bash
./scripts/install louie
```

## Stuck `nixos-rebuild switch` (transient unit already loaded)

If the switch fails with:

```
Failed to start transient service unit: Unit nixos-rebuild-switch-to-configuration.service was already loaded or has a fragment file.
```

A previous `switch-to-configuration` process is usually still **active/hung** (often stuck
in os-prober), which keeps the unit loaded and blocks the next run. Confirm it is stuck:

```bash
systemctl status nixos-rebuild-switch-to-configuration.service
systemctl list-units --all | grep nixos-rebuild
```

If it shows `Active: active (running)`, kill it and force systemd to drop the in-memory
transient unit (`daemon-reload` is NOT enough — use `daemon-reexec`):

```bash
sudo systemctl stop nixos-rebuild-switch-to-configuration.service 2>/dev/null
sudo systemctl kill -s KILL nixos-rebuild-switch-to-configuration.service 2>/dev/null
sudo systemctl reset-failed
sudo systemctl daemon-reexec
./scripts/install louie
```

### Fallback: activate manually

If it still errors, the new generation is already built and the system
profile was updated. Run the switch script directly to bypass the stuck
`systemd-run` unit:

```bash
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

Verify afterwards with `sudo nixos-rebuild boot` or a reboot.

### Clean up a stale fragment (if needed)

```bash
ls /etc/systemd/system/nixos-rebuild-switch-to-configuration.service
# remove it if present
```

## Notes

- `warning: Git tree '/home/daniel/dotfiles' is dirty` is harmless. It means
  there are uncommitted changes in the dotfiles repo. Commit them to silence
  it; it does not block the build.
- Perl locale warnings about `es_VE.UTF-8` were fixed by adding
  `i18n.extraLocaleSettings` to `nixos/hosts/louie/user.nix`.
