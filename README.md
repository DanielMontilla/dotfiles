# dotfiles

Config files for all machines. One **profile** per machine under `profiles/`,
each in one of three modes chosen by a marker file:

| Marker | Mode | What it does |
|--------|------|--------------|
| `.nixos` | nixos | Full NixOS system: `sudo nixos-rebuild switch --flake ".#<name>"` |
| `.nix-profile` | nix-profile | User packages: `nix profile add path:profiles/<name>/nixos` |
| `.windows` | windows | No nix — just links config files with dotbot (needs Python 3.7+) |

`scripts/install <name>` installs packages (or checks prerequisites for
windows profiles). `scripts/link <name>` always links config via dotbot.

## Profiles

| Profile | Machine | Mode | Config |
|---|---|---|---|
| `hocotate` | NixOS | nixos | `nixos/hosts/hocotate/` |
| `louie` | NixOS | nixos | `nixos/hosts/louie/` |
| `olimar` | NixOS | nixos | `nixos/hosts/olimar/` + `profiles/olimar/` |
| `oatchi` | WSL | nix-profile | `profiles/oatchi/` |
| `koppai` | Windows | windows | [`profiles/koppai/README.md`](profiles/koppai/README.md) |

Shared, app-level configs (alacritty, fish, git, neovim, starship, zed, ...)
live in `profiles/shared/<app>/` and are referenced by each profile's
`dotbot.yaml` by repo-relative path.

## Scripts

On **Linux/WSL** (bash):

```bash
./scripts/install <name>   # install packages / check prerequisites
./scripts/link <name>      # link config files with dotbot
./scripts/update <host>    # nix flake update + rebuild (NixOS hosts only)
```

On **Windows** (PowerShell, no bash needed):

```powershell
.\scripts\install.ps1 <name>   # windows profiles: check Python 3.7+ + dotbot, pip-install dotbot
.\scripts\link.ps1 <name>      # run dotbot against the profile's dotbot.yaml
```

- `install` picks the mode from the marker file in `profiles/<name>/`.
- `link` runs `dotbot -d <repo> -c profiles/<name>/dotbot.yaml`. Needs
  `dotbot` on PATH (nix modes get it from the profile; windows mode installs
  it via pip), falling back to `python -m dotbot` if the binary isn't on PATH.
- Install **before** link on nix machines (link needs the `dotbot` binary).

## Windows profiles (koppai)

No nix at all. `scripts/install.ps1 koppai` only verifies Python 3.7+ and
installs dotbot via pip; `scripts/link.ps1 koppai` then symlinks configs into
the Windows user profile (`~/AppData/Roaming/...`). Symlinks on Windows require
Developer Mode or an elevated shell. Details in
[`profiles/koppai/README.md`](profiles/koppai/README.md).

## Conventions

- Profile configs are YAML (`dotbot.yaml`) consumed by dotbot; paths are
  relative to the repo root.
- Windows destinations use `~/...` (dotbot expands `~` to the user profile
  dir — on Windows that's `C:\Users\<you>`).
- Keep per-machine stuff out of `profiles/shared/`; put it in the profile.
