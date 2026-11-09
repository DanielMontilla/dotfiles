# pikpik — macOS (work)

Profile for a macOS work laptop. macOS stays the OS; Nix provides **user-level
CLI packages only**, dotbot links configs, and the machine joins the existing
**Tailscale mesh** so it can SSH to `olimar`/`louie` (and they to it).

This is the `nix-profile` mode (same as `oatchi`), so `scripts/install` needs no
new code path. If you later want declarative macOS defaults, launchd, or
Homebrew casks, add a `nix-darwin` layer on top; this profile deliberately
avoids touching the system on a work machine.

## Layout

```
profiles/pikpik/
├── .nix-profile          # mode marker (read by scripts/install)
├── nixos/flake.nix       # aarch64-darwin buildEnv + devShell
├── dotbot.yaml           # links ssh config, fish, nvim, starship
├── vendor-apps.sh        # optional idempotent curl installers
├── ssh/config            # client config: pikpik -> olimar/louie
├── ssh/authorized_keys   # source of truth: olimar/louie -> pikpik
└── README.md
```

## 1. Install Nix (once)

Use the Determinate Systems installer — it handles upgrades and uninstall, and
enables flakes by default:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

It needs admin rights. Verify with `nix --version`.

If the Mac is Intel, change `system = "aarch64-darwin";` to
`"x86_64-darwin"` in `nixos/flake.nix` (check with `uname -m`).

## 2. Install packages and link configs

From the repo root on pikpik:

```bash
./scripts/install pikpik   # nix profile add path:profiles/pikpik/nixos
./scripts/link pikpik      # dotbot
```

`install` brings in the CLI tools plus Zed, Ghostty, Claude Code, Codex, and
Herdr (see 2b–2d); `link` only links config files.

> **Gotcha:** `nix profile` names the entry after the flake directory (`nixos`),
> not the profile. `scripts/install` already accounts for this; don't run
> `nix profile upgrade pikpik` manually.

## 2b. Zed (prebuilt app, not a source build)

`nixpkgs` does have `zed-editor`, but on Darwin it is a **from-source Rust
build** and there is no official `aarch64-darwin` binary cache — installing it
can compile Zed and WebRTC for a very long time. This flake instead packages the
official **prebuilt** `.dmg` (the same artifact the curl installer downloads),
pinned by version and SHA-256 in `nixos/flake.nix` (`zedVersion`).

After the profile is installed, expose the app to Finder/Launchpad:

```bash
mkdir -p ~/Applications
ln -sfn ~/.nix-profile/Applications/Zed.app ~/Applications/Zed.app
```

`~/.nix-profile` is stable across profile upgrades, so the symlink survives.
The CLI is on PATH as both `zed` and `zeditor` (the latter keeps the shared
fish `zed` function working).

Notes:

- **Auto-update won't work** — the app lives in the read-only Nix store. Update
  via Nix: bump `zedVersion`, blank both `zedHash` values, run
  `nix build path:profiles/pikpik/nixos#zed`, then paste the hashes from the
  error. Then `./scripts/install pikpik`.
- **Prefer vendor tools?** `brew install --cask zed` is the pragmatic
  alternative; drop `zed` from `profilePackages` and the two Zed lines in the
  fish config become inert because of the `type -q zeditor` guard.

## 2c. Ghostty (prebuilt app)

Ghostty's own flake **cannot build on macOS** — it needs Swift 6 and
`xcodebuild`, which nixpkgs does not provide. The Linux hosts keep using the
upstream flake input; pikpik uses the official **universal** macOS app (works
on Apple Silicon and Intel), pinned by version and SHA-256 in
`nixos/flake.nix` (`ghosttyVersion`).

The `.zip` is used rather than the `.dmg` because Ghostty's DMG is APFS and
nixpkgs' `undmg` only reads HFS.

Expose the app to Finder/Launchpad:

```bash
mkdir -p ~/Applications
ln -sfn ~/.nix-profile/Applications/Ghostty.app ~/Applications/Ghostty.app
```

The CLI is on PATH as `ghostty`.

If you previously installed Ghostty from its DMG, remove
`/Applications/Ghostty.app` first so Launchpad does not show two copies.

Notes:

- **Sparkle auto-update can't replace the app** inside the read-only Nix store.
  Update via Nix: bump `ghosttyVersion`, blank `ghosttyHash`, run
  `nix build path:profiles/pikpik/nixos#ghostty`, paste the hash from the
  error, then `./scripts/install pikpik`.
- **Config is not linked:** `profiles/shared/ghostty/config` is tuned for
  GTK/Linux (`gtk-single-instance`, `window-decoration`) and sets
  `command = fish`, which a Finder-launched app may not find on PATH. On macOS
  use `~/Library/Application Support/com.mitchellh.ghostty/config` (or the XDG
  path `~/.config/ghostty/config`) instead.
- Ghostty 1.4 requires **macOS 13+ (Ventura)**.

## 2d. Claude Code, Codex, and Herdr

All three are in the profile, so no curl installer is needed:

| Command | Source | Notes |
|---|---|---|
| `claude` | `nixpkgs-unstable.claude-code` (stable on Intel) | Anthropic license (unfree); allowed only for this package via `allowUnfreePredicate` |
| `codex` | pinned prebuilt `codex-package-*-apple-darwin.tar.gz` | same artifact the OpenAI installer downloads (includes helpers + ripgrep) |
| `herdr` | `nixpkgs-unstable.herdr` (prebuilt release on Intel) | cached for aarch64-darwin; unstable dropped x86_64-darwin |

Claude Code is a prebuilt binary in nixpkgs, so it does not compile. Codex is
packaged here as a prebuilt tarball because nixpkgs' `codex` compiles from Rust
source, which is very slow on Darwin. Herdr is nixpkgs-unstable's package on
Apple Silicon (already in the official binary cache, with its integration
assets); Intel uses the upstream prebuilt binary because nixpkgs-unstable no
longer supports x86_64-darwin.

If you already installed any of these with curl, remove the old binary so the
Nix one wins (keep the data dirs):

```bash
rm -f ~/.local/bin/claude ~/.local/bin/codex ~/.local/bin/zed ~/.local/bin/herdr
which -a claude codex zed herdr    # Nix entries under ~/.nix-profile/bin should win
```

**Herdr config is not linked:** `profiles/shared/herdr/` includes Linux/Windows
notification plugins. Link only `config.toml` on macOS if you want the same
prefix key, theme, and fish default shell.

## 2e. Apps that are not in nixpkgs (`vendor-apps.sh`)

For anything not packaged, edit `profiles/pikpik/vendor-apps.sh` and add one
line per app:

```bash
vendor_app "mytool" \
    "[ -x \"$HOME/.local/bin/mytool\" ] || command -v mytool" \
    sh -c 'curl -fsSL https://example.com/install.sh | sh'
```

`scripts/install pikpik` runs that file after the Nix step. The `check` runs
first, so an already-installed app is skipped and re-running install is
idempotent. These installs are outside Nix's reproducibility/uninstall
guarantees — prefer packaging the release (as done for Zed, Ghostty, and Codex)
when it matters.

## 3. Install Tailscale

Use the **macOS app**, not the nixpkgs package: only the app ships the Network
Extension and integrates with macOS networking.

```bash
brew install --cask tailscale      # or install "Tailscale" from the App Store
```

1. Open the app and sign in to the **same tailnet** as olimar/louie
   (`tail5c357b`).
2. In the Tailscale admin console, rename this device to **pikpik** so MagicDNS
   gives it `pikpik.tail5c357b.ts.net`.
3. Verify:

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale status
/Applications/Tailscale.app/Contents/MacOS/Tailscale ping olimar
```

The app's CLI is capital-`T` `Tailscale`. Add an alias if you like:

```bash
alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
```

> **Work-machine caveat:** corporate MDM can block system extensions, and using
> a personal tailnet on a work laptop may violate policy. Confirm with IT. The
> macOS app can switch between tailnets, but not join two at once.

## 4. Create the machine key (once)

```bash
ssh-keygen -t ed25519 -C "daniel@pikpik"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

`ssh/config` sets `UseKeychain yes`, so the passphrase lives in the login
Keychain. Keep the private key on pikpik.

## 5. pikpik → olimar / louie

Add pikpik's public key to each NixOS host's `authorizedKeys`. There is a
commented placeholder in both files:

- `nixos/hosts/olimar/ssh.nix`
- `nixos/hosts/louie/ssh.nix`

Paste the line, then rebuild each host from the repo root:

```bash
cd nixos
sudo nixos-rebuild switch --flake ".#olimar"
sudo nixos-rebuild switch --flake ".#louie"
```

Then, on pikpik:

```bash
ssh olimar
ssh louie
```

Both servers are key-only on port **2222**, and the firewall already allows it.
The client config for those hosts is linked from `ssh/config`.

## 6. olimar / louie → pikpik

This direction uses the macOS **system sshd** (Remote Login), not Nix. On
pikpik:

```bash
# GUI: System Settings → General → Sharing → Remote Login
# CLI:
sudo systemsetup -setremotelogin on
sudo systemsetup -getremotelogin      # "Remote Login: On"
```

Then authorize the Linux hosts' existing keys:

```bash
cat profiles/pikpik/ssh/authorized_keys >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

Those keys are the same `daniel@olimar` / `daniel@louie` keys already used on
the mesh. From either Linux box:

```bash
ssh pikpik            # config in profiles/{olimar,louie}/ssh/config
# or without the alias:
ssh pikpik.tail5c357b.ts.net
```

Inbound to pikpik is port **22** (macOS default); outbound to the Linux boxes
stays **2222**. If you want 2222 inbound too, edit `/etc/ssh/sshd_config`
(`Port 2222`) and restart `sshd` — that file is outside this repo in
nix-profile mode.

Optional hardening: set `PasswordAuthentication no` in `/etc/ssh/sshd_config`
(back it up first, keep an active session open, then restart):

```bash
sudo launchctl kickstart -k system/com.openssh.sshd
```

## 7. Verify

```bash
# on pikpik
ssh olimar 'hostname'
ssh louie 'hostname'

# on olimar or louie
ssh pikpik 'hostname'

# path/debug
tailscale ping olimar
ssh -v olimar
```

## Troubleshooting

| Symptom | Likely fix |
|---|---|
| `Could not resolve hostname ...ts.net` | Tailscale not connected, or MagicDNS off. Check `Tailscale status`; use the `100.x` IP temporarily. |
| `Permission denied (publickey)` | pikpik's pubkey isn't in that host's `ssh.nix`, or the host wasn't rebuilt. |
| `Connection refused` on port 2222 | The NixOS host lacks `./ssh.nix` in `configuration.nix`, or the firewall/rebuild didn't apply. |
| Linux → pikpik times out | Remote Login is off, or the macOS firewall is blocking `sshd`. |
| `Bad configuration option: UseKeychain` | You're running nixpkgs `openssh`, which shadows `/usr/bin/ssh`; remove it from the PATH/profile. |
| Key passphrase asked every time | `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`, and keep `UseKeychain yes`. |
| Works on LAN but not away | `tailscale status` / `tailscale netcheck`; check tailnet ACLs (default allows all). |

## Notes

- **Mosh:** `mosh olimar` works (olimar enables `programs.mosh`). louie does not
  yet — use plain `ssh louie`, or add `programs.mosh.enable = true;` to
  `nixos/hosts/louie/packages.nix`.
- **No git config linked:** the shared `~/.gitconfig` uses a personal identity.
  Create `profiles/pikpik/gitconfig` with your work name/email and link it.
- **No Zed config linked:** `profiles/shared/zed/` hardcodes a NixOS fish path;
  a macOS Zed config needs its own copy.
- **Backups:** exclude `/nix` from Time Machine — it is reproducible and large.
- **Tailscale key expiry:** personal tailnets expire device keys (180 days by
  default). Disable expiry for pikpik in the admin console if that's annoying.
