# koppai — Windows (no nix)

Profile for a **native Windows machine**. No Nix, no WSL, no dotbot-via-nix —
just dotbot linking config files into the Windows user profile.

## Layout

```
profiles/koppai/
├── .windows        # mode marker: "windows, no nix" (read by scripts/install)
├── dotbot.yaml     # dotbot config (same format as every other profile)
├── ssh/config      # SSH config for the mesh (olimar over Tailscale)
└── README.md
```

## Prerequisites (one-time)

- **Python 3.7+** — required by dotbot. Install from
  <https://www.python.org/downloads/> and tick *"Add python.exe to PATH"*.
- **dotbot** — installed automatically by `scripts/install.ps1 koppai` via
  `python -m pip install --user dotbot`.
- **Developer Mode** (or an elevated shell) — dotbot creates real symlinks,
  and on Windows those need Developer Mode or admin rights:
  *Settings → Privacy & security → For developers → Developer Mode*.

No bash needed on Windows — the PowerShell scripts are the entrypoint here
(`scripts/install.ps1` / `scripts/link.ps1`). The bash `./scripts/*` are for
the nix machines, which always have bash.

If PowerShell blocks the scripts with a "running scripts is disabled" error,
allow local scripts once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Setup

From a PowerShell terminal at the repo root, **on the Windows machine**:

```powershell
.\scripts\install.ps1 koppai   # checks Python 3.7+, installs dotbot if missing
.\scripts\link.ps1 koppai      # runs dotbot against profiles/koppai/dotbot.yaml
```

Nothing else — there are no packages to install on Windows.

## What gets linked

| Repo source | Windows destination |
|---|---|
| `profiles/shared/zed/*` | `~/AppData/Roaming/Zed/` (i.e. `%APPDATA%\Zed`) |
| `profiles/koppai/ssh/config` | `~/.ssh/config` |

Because it's a symlink, edits you make in Zed write straight back into the
repo (commit them like any other change).

## Remote development: SSH from koppai to olimar

The mesh: koppai (Windows, Zed UI) connects over **Tailscale** to olimar
(NixOS, runs the Zed headless server). Key-only SSH on port 2222 — no
passwords. The shared `zed/settings.json` already declares the connection
(`ssh_connections` → host `olimar`, project `~/dotfiles`), and
`~/.ssh/config` is linked from `profiles/koppai/ssh/config`.

### One-time setup on Windows (koppai)

1. **Install Tailscale** and sign in to the same tailnet:
   ```powershell
   winget install Tailscale.Tailscale
   # sign in via the system tray icon, then verify olimar is visible:
   tailscale status
   ```
2. **Verify the OpenSSH client** (built into Windows 10/11):
   ```powershell
   ssh -V
   ```
3. **Generate koppai's key** (keep the private key on this machine only):
   ```powershell
   ssh-keygen -t ed25519 -C "daniel@koppai" -f $env:USERPROFILE\.ssh\id_ed25519
   Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub   # ← paste this somewhere safe
   ```
4. **Add that public key to olimar**: it goes into
   `nixos/hosts/olimar/ssh.nix` under `authorizedKeys` (as `daniel@koppai`,
   like the `daniel@louie` / `daniel@oatchi` entries), then rebuild on olimar:
   ```bash
   sudo nixos-rebuild switch --flake ".#olimar"
   ```
5. **Enable the ssh-agent service** and load the key:
   ```powershell
   Set-Service ssh-agent -StartupType Automatic
   Start-Service ssh-agent
   ssh-add $env:USERPROFILE\.ssh\id_ed25519
   ```
6. **Test the connection** (first run accepts the host key):
   ```powershell
   ssh olimar
   ```

### In Zed

- `ctrl-alt-shift-o` (Windows) → Remote Projects → `olimar` should be listed
  (it's in `ssh_connections`). Click it and open `~/dotfiles`.
- Or from a terminal: `zed ssh://olimar/~/dotfiles`.
- Zed downloads/updates the headless server on olimar automatically on first
  connect; extensions you have locally are propagated to the server.

### Troubleshooting

- **ssh.exe not found by Zed**: make sure `C:\Windows\System32\OpenSSH` is on
  PATH.
- **Permission denied (publickey)**: the koppai pubkey isn't in olimar's
  `authorizedKeys` yet (step 4), or you're on a stale NixOS generation.
- **Can't resolve `olimar.tail5c357b.ts.net`**: Tailscale isn't running or
  signed in on Windows, or koppai isn't on the same tailnet.
- **Key not found despite `IdentityFile ~/.ssh/id_ed25519`**: some OpenSSH
  builds on Windows mishandle `~` in config. Replace it with an absolute path
  (`C:/Users/<you>/.ssh/id_ed25519`) in `profiles/koppai/ssh/config`.

## Gotchas

- **Symlinks need Developer Mode.** If `scripts/link.ps1 koppai` fails with
  permission errors, enable Developer Mode (see above) and re-run.
- **Existing regular files block links.** If `settings.json` already exists
  as a real file (you've used Zed before), dotbot aborts with *"already
  exists but is a regular file or directory"*. Delete or move it first:
  `mv ~/AppData/Roaming/Zed ~/AppData/Roaming/Zed.bak`.
- **Keep the repo on the same drive as `C:\Users\...`.** dotbot uses
  relative symlinks (`relative: true`, repo default); relative links can't
  cross drives. If the repo lives on `D:\`, set `relative: false` in
  `dotbot.yaml` to get absolute links.
- **Re-running** `\scripts\link.ps1 koppai` re-syncs (relinks) everything.

## Adding more apps

Append to `dotbot.yaml` using `~/...` paths (dotbot expands `~` to the
Windows user profile dir). Examples:

```yaml
- link:
    "~/AppData/Roaming/Zed/":
      path: profiles/shared/zed/*
    "~/.gitconfig":
      path: profiles/shared/git/gitconfig
    "~/AppData/Roaming/Code/User/settings.json":
      path: profiles/koppai/vscode/settings.json
```
