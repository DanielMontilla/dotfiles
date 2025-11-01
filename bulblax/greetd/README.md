# Greetd Setup

## Install
```bash
sudo dnf install greetd greetd-tuigreet dbus-x11
```

## Disable Other Display Managers & Enable Greetd

First, check what display manager is currently enabled:
```bash
systemctl list-unit-files | grep -E 'gdm|sddm|lightdm|greetd'
```

Disable any other display managers (e.g., GDM):
```bash
sudo systemctl disable gdm.service  # or sddm, lightdm, etc.
```

Enable greetd:
```bash
sudo systemctl enable greetd.service
```

Verify greetd is enabled:
```bash
systemctl is-enabled greetd.service
```

Set default target to graphical mode (required for greetd to start on boot):
```bash
sudo systemctl set-default graphical.target
systemctl get-default  # should show graphical.target
```

## Link Config
```bash
# Remove default config
sudo rm /etc/greetd/config.toml

# Link dotfiles config
sudo ln -s /home/daniel/dotfiles/bulblax/greetd/config.toml /etc/greetd/config.toml
```

## Test
```bash
# Verify link
ls -la /etc/greetd/config.toml

# Manual test (takes over terminal)
sudo greetd --config /etc/greetd/config.toml
```

## Start
```bash
sudo systemctl start greetd.service
```

## Fix PAM Configuration

The default greetd PAM config is missing `pam_systemd.so`, which causes `XDG_RUNTIME_DIR` errors. Edit the PAM config:

```bash
sudo nano /etc/pam.d/greetd
```

Add this line in the session section (after `session required pam_unix.so`):
```
session    optional   pam_systemd.so
```

The complete file should look like:
```
#%PAM-1.0
auth       required   pam_env.so
auth       sufficient pam_unix.so try_first_pass nullok
auth       required   pam_deny.so
account    sufficient pam_unix.so
account    required   pam_permit.so
password   required   pam_unix.so try_first_pass nullok sha512 shadow
session    required   pam_unix.so
session    optional   pam_systemd.so
session    optional   pam_env.so
```

Then restart:
```bash
sudo systemctl restart greetd.service
```

## Troubleshooting

### XDG_RUNTIME_DIR Error
Should be fixed by the PAM configuration above.

### Bypass tuigreet (Direct TTY Login)
Press `Ctrl+Alt+F2` (or F3, F4, etc.) to switch to a different TTY for direct login without tuigreet.

To return to the greetd TTY, press `Ctrl+Alt+F1`.

