# pikpik — macOS (work)

Apple Silicon work laptop, declared with **nix-darwin**: CLI packages, Nix
settings, sshd, Homebrew casks, and macOS defaults live in Nix; dotbot links the
dotfiles. The machine joins the existing **Tailscale mesh** so it can SSH to
`olimar`/`louie` (and they to it).

This is the `nix-darwin` mode: `scripts/install` runs `darwin-rebuild switch`
instead of `nix profile add`.

## Layout

```
profiles/pikpik/
├── .nix-darwin            # mode marker (read by scripts/install)
├── nixos/flake.nix        # inputs + darwinConfigurations.pikpik + devShell
├── nixos/configuration.nix# the system: packages, nix, sshd, casks, defaults
├── nixos/packages.nix     # CLI package list shared with the dev shell
├── nixos/flake.lock       # pinned inputs (update: ./scripts/update pikpik)
├── dotbot.yaml            # links ssh config.d, fish, nvim, starship, ghostty
├── ghostty/config         # macOS Ghostty config (incl. the drop-down hotkey)
├── vendor-apps.sh         # only warns about shadowing ~/.local/bin leftovers
├── ssh/config             # client config: pikpik -> olimar/louie
└── README.md
```

## 1. Install Nix (once)

Use the **official** installer (this is what pikpik was set up with):

```bash
sh <(curl -L https://nixos.org/nix/install)
```

It needs admin rights. Open a new terminal afterwards, then `nix --version`.

Unlike Determinate's installer it leaves `nix-command` and `flakes` disabled, so
run this once from the repo root:

```bash
./scripts/enable-nix-features
```

nix-darwin takes over `/etc/nix/nix.conf` from then on, so this script is only
needed to bootstrap.

## 2. Install nix-darwin (first run)

### First, install Homebrew (once)

nix-darwin **does not install Homebrew**. Its `homebrew` module is a driver: it
writes a Brewfile and runs `brew bundle` against an existing install. The module
checks for `${homebrew.prefix}/bin/brew` during activation and aborts if it is
missing, so install it *before* the first rebuild (the installer is interactive
and wants your password):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On Apple Silicon that puts `brew` in `/opt/homebrew/bin`. `scripts/install`
runs the same check before it builds, so a missing Homebrew costs you seconds,
not a full rebuild.

> If you would rather have Nix own Homebrew too, add the
> [`nix-homebrew`](https://github.com/zhaofengli/nix-homebrew) flake input — it
> installs and pins Homebrew declaratively. It is an extra input and a larger
> surface, which is why this profile does not use it.

### Then bootstrap nix-darwin

```bash
git clone https://github.com/DanielMontilla/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/install pikpik
```

On the first run `darwin-rebuild` does not exist yet, so `scripts/install`:

1. moves `/etc/nix/nix.conf` to `/etc/nix/nix.conf.before-nix-darwin` (nix-darwin
   refuses to overwrite a file it does not recognise, and the bootstrap script
   above modified it);
2. runs `nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch` with the
   experimental features passed explicitly for that one invocation.

Afterwards `/etc/nix/nix.conf` is a symlink into the Nix store managed by
`nix.settings`, and later runs are just `sudo darwin-rebuild switch`.

It will ask for your password. First build downloads a few hundred MiB.

## 3. Link configs

```bash
./scripts/link pikpik
```

Links `~/.ssh/config.d/pikpik.conf`, `~/.config/fish/config.fish`,
`~/.config/nvim`, `~/.config/starship.toml`, and the Ghostty config into
`~/Library/Application Support/com.mitchellh.ghostty/config`.

dotbot replaces existing **symlinks** (`relink: true`) but refuses to overwrite
a regular file it did not create. If Ghostty (or you) already wrote a config
there, move it aside first:

```bash
mv ~/Library/Application\ Support/com.mitchellh.ghostty/config{,.bak}
./scripts/link pikpik
```

## 4. Make fish your login shell

macOS keeps `/bin/zsh` as the login shell, and **nix-darwin cannot change the
shell of an account it did not create** — `users.knownUsers` is only for
accounts nix-darwin owns, and its own docs say not to put the admin user there.
So rather than mutating the account record, this profile hands interactive zsh
to fish with a linked config file:

`profiles/pikpik/zshrc` → `~/.zshrc`:

```zsh
if [[ -o interactive ]] && [[ -z $FISH_VERSION ]] && [[ -x /run/current-system/sw/bin/fish ]]; then
    exec /run/current-system/sw/bin/fish
fi
```

Ghostty, Terminal, VS Code, and an interactive `ssh` into this Mac all start an
interactive zsh, so all of them land in fish. Non-interactive shells
(`zsh -c ...`, scripts) are deliberately left alone. `scripts/link pikpik`
installs it like any other config; no extra step.

The shared fish config also exports `SHELL` on Darwin so tools that spawn
`"$SHELL"` (the `nd` alias, for example) get fish rather than the zsh the
account record still says.

Check in a **new** terminal:

```bash
echo $SHELL        # /run/current-system/sw/bin/fish (set by fish itself)
echo $FISH_VERSION # non-empty: you are in fish
starship --version # from nixos/packages.nix
```

fish reads the linked `~/.config/fish/config.fish`, which starts starship with
the linked `~/.config/starship.toml` — same setup as the Linux profiles.

> **Why not `chsh`?** It changes the account record, which is OS state like the
> password, not dotfiles state — and on a work Mac an MDM profile can pin it
> anyway. If you want `$SHELL` to be truthful before fish starts (e.g. for
> non-interactive `ssh host command`), run `chsh -s /run/current-system/sw/bin/fish`
> once; it is optional and the zshrc handoff keeps working either way.
>
> **If `~/.zshrc` already exists** (corporate setup), dotbot will refuse to
> replace a regular file — see §3. Move it aside first; nothing is overwritten
> silently.

## 5. Apps (Homebrew casks)

Declared in `nixos/configuration.nix`:

| Cask | Why not Nix |
|---|---|
| `zed` | Cask tracks the latest release (`autobump`), and Zed **updates itself**. The Nix-packaged app lives in the read-only store, so auto-update was impossible. |
| `ghostty` | Same: self-updating, and a stable `/Applications` path keeps permission grants alive. |
| `tailscale-app` | Needs the Network Extension; only the app ships it. Homebrew renamed this cask from `tailscale` to `tailscale-app` — the old token still installs but prints a rename warning. |

Homebrew is installed in §2; `darwin-rebuild switch` then runs `brew bundle` and
installs the casks. Notes:

- All three casks are `auto_updates: true`, so Homebrew deliberately skips them
  in `brew upgrade`. They update themselves; force it with
  `brew upgrade --cask --greedy zed ghostty tailscale-app`.
- `homebrew.onActivation.cleanup` is `"none"` on purpose — `"zap"` would delete
  `~/.config/zed` and `~/Library/Application Support/com.mitchellh.ghostty`,
  i.e. the linked config.
- The Zed CLI is `/opt/homebrew/bin/zed`. The cask does **not** ship `zeditor`,
  so the shared fish `zed` wrapper (guarded by `type -q zeditor`) is inert and
  `zed` opens in the foreground.

### Terminal hotkey

`ghostty/config` binds `ctrl+backquote` to `toggle_quick_terminal`: a
Quake-style drop-down terminal, available system-wide.

Ghostty must be granted **Accessibility** permission for a `global:` keybind
(System Settings → Privacy & Security → Accessibility). If the hotkey stops
working after an update, toggle Ghostty off/on in that list.

Change the key in `profiles/pikpik/ghostty/config` (`global:cmd+backquote=...`
is the classic choice, but macOS uses Cmd+\` for window cycling).

## 6. Claude Code, Codex, and Herdr

All three come from Nix (`nixos/packages.nix`), no curl installer:

| Command | Source | Notes |
|---|---|---|
| `claude` | `nixpkgs-unstable.claude-code` | Anthropic license (unfree); allowed only for this package |
| `codex` | pinned prebuilt `codex-package-aarch64-apple-darwin.tar.gz` | nixpkgs' `codex` builds from Rust source, which is very slow on Darwin |
| `herdr` | `nixpkgs-unstable.herdr` | already in the aarch64-darwin binary cache |

If you previously installed any of these with curl, remove the old binary so the
managed one wins (keep the data dirs):

```bash
rm -f ~/.local/bin/claude ~/.local/bin/codex ~/.local/bin/zed ~/.local/bin/herdr
type -a claude codex zed herdr
```

**Herdr config is not linked:** `profiles/shared/herdr/` includes Linux/Windows
notification plugins. Link only `config.toml` on macOS if you want the same
prefix key, theme, and fish default shell.

## 7. Tailscale

The cask is installed by nix-darwin, but signing in is manual:

1. Open **Tailscale** and sign in to the same tailnet as olimar/louie
   (`tail5c357b`).
2. In the admin console, rename this device to **pikpik** so MagicDNS gives it
   `pikpik.tail5c357b.ts.net`.
3. Verify:

```bash
tailscale status
tailscale ping olimar
```

The CLI lives inside the app bundle (`/Applications/Tailscale.app/Contents/MacOS/Tailscale`).
The pkg also drops `/usr/local/bin/tailscale`, but fish does not read
`/etc/paths`, so that directory is often missing from `PATH`. The shared fish
config therefore defines a `tailscale` function pointing at the bundle, which
is why plain `tailscale status` works. You never have to open the GUI after
the one-time login — but the app must stay installed and running as a login
item, because it owns the tunnel and the Network Extension.

> **CLI-only alternative:** `brew install tailscale` installs `tailscaled` and
> a real CLI, and `sudo brew services start tailscale` runs it. It conflicts
> with the app (both manage `utun` and routes), so remove the cask first, and
> MagicDNS/`.ts.net` names are not reliably set up by the OSS daemon on macOS —
> which is what this profile's SSH configs rely on. Keep the app unless you
> have a reason not to.

> **Work-machine caveat:** corporate MDM can block system extensions, and using
> a personal tailnet on a work laptop may violate policy. Confirm with IT. The
> macOS app can switch between tailnets, but not join two at once.

## 8. Create the machine key (once)

```bash
ssh-keygen -t ed25519 -C "danielmontilla@pikpik"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

`ssh/config` sets `UseKeychain yes`, so the passphrase lives in the login
Keychain. Keep the private key on pikpik.

## 9. pikpik → olimar / louie

pikpik's key is already in both NixOS hosts (`nixos/hosts/{olimar,louie}/ssh.nix`,
fingerprint `SHA256:eiQ5u0YqSr6GgwYK5Gm7/F9TmR4chsZOFyHUGGcEdbQ`), so only a
rebuild is needed — after `git pull` on each host:

```bash
cd nixos
sudo nixos-rebuild switch --flake ".#olimar"
sudo nixos-rebuild switch --flake ".#louie"
```

Then, on pikpik:

```bash
cd ~/dotfiles && git pull --ff-only
./scripts/ssh-setup pikpik
```

That runs `scripts/link` (which puts the client config at
`~/.ssh/config.d/pikpik.conf` instead of overwriting `~/.ssh/config`, since a
work Mac may already have a corporate config), then:

1. prepends `Include config.d/*` to `~/.ssh/config` if it is not already the
   first directive — ssh keeps the *first* value it sees, so it must come
   before any `Host *` block;
2. fixes permissions (`700` on `~/.ssh`, `600` on the config);
3. loads the key into the login Keychain with `ssh-add --apple-use-keychain`;
4. prints what ssh actually resolves for every `Host`, and warns if the
   drop-in is not in effect.

Re-running it is safe; it only changes what is missing. Add `--test` to also
try a real connection to each host:

```bash
./scripts/ssh-setup pikpik --test
```

Both servers are key-only on port **2222**, and the firewall already allows it.
Then:

```bash
ssh olimar
ssh louie
```

## 10. olimar / louie → pikpik

`services.openssh.enable = true` in `configuration.nix` turns on Remote Login,
so there is no `systemsetup` step. It is **key-only**, and the allowed keys are
declared in the same file:

```nix
users.users.danielmontilla.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... daniel@olimar"
  "ssh-ed25519 AAAA... daniel@louie"
];
```

nix-darwin writes them to `/etc/ssh/nix_authorized_keys.d/<user>` and reads that
through sshd's `AuthorizedKeysCommand` — *in addition to* the usual
`~/.ssh/authorized_keys`, which is left alone. So there is nothing to append by
hand, and an existing file on a work Mac keeps working.

Those are the same `daniel@olimar` / `daniel@louie` keys already used on the
mesh. From either Linux box:

```bash
ssh pikpik            # config in profiles/{olimar,louie}/ssh/config
# or without the alias:
ssh pikpik.tail5c357b.ts.net
```

Inbound to pikpik is port **22**; outbound to the Linux boxes stays **2222**.
To change the inbound port, add `Port 2222` to `services.openssh.extraConfig`
and rebuild (it is `/etc/ssh/sshd_config.d/100-nix-darwin.conf`).

## 11. Verify

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

## 12. Remove the old nix profile (one-time)

Before the migration pikpik installed packages with `nix profile add`. nix-darwin
keeps `$HOME/.nix-profile` **first** in `PATH`, so those packages keep shadowing
the system ones — `fish`, `git`, `neovim`, `codex`, `claude`, `herdr`, and the
Nix-packaged Zed/Ghostty apps.

Run this **after** §4 (`chsh`) has worked and a fresh terminal starts with the
new fish. If your login shell is still `~/.nix-profile/bin/fish`, emptying the
profile leaves you with no shell to log in to.

```bash
nix profile list          # what is in there, and which flake it came from
nix profile remove --all  # empty the profile
nix profile wipe-history --older-than 0d   # drop the old generations
```

The old `vendor-apps.sh` also put `Zed.app` / `Ghostty.app` symlinks into
`~/Applications`. They point into the store, so they are dangling now (and
Spotlight shows a second Zed/Ghostty next to the casks):

```bash
ls -l ~/Applications
for app in Zed Ghostty; do
    [ -L "$HOME/Applications/$app.app" ] && rm "$HOME/Applications/$app.app"
done
```

Reclaim the space — plain `nix-collect-garbage`, **without** `-d`, so
`darwin-rebuild --rollback` keeps its generations:

```bash
nix-collect-garbage
sudo nix-collect-garbage
```

Keep `/etc/nix/nix.conf.before-nix-darwin` until the new system is verified, then
delete it.

## Updating

```bash
cd ~/dotfiles
./scripts/update pikpik     # nix flake update, then darwin-rebuild switch
```

That refreshes nixpkgs and nix-darwin, then rebuilds. The casks self-update on
their own; use `brew upgrade --cask --greedy <name>` to force one.

Rollback if a generation misbehaves:

```bash
sudo darwin-rebuild --list-generations
sudo darwin-rebuild --rollback
```

## Troubleshooting

| Symptom | Likely fix |
|---|---|
| `error: Unexpected files in /etc, aborting activation` | Something else wrote a file nix-darwin owns. Rename it with a `.before-nix-darwin` suffix, then rebuild. |
| `Unexpected files in /etc: /etc/nix/nix.conf` | `sudo mv /etc/nix/nix.conf{,.before-nix-darwin}` — nix-darwin manages that file now. |
| `experimental Nix feature 'nix-command' is disabled` | Only on a fresh Mac: `./scripts/enable-nix-features`. After the first `darwin-rebuild` this comes from `nix.settings`. |
| `Could not resolve hostname ...ts.net` | Tailscale not connected, or MagicDNS off. Check `Tailscale status`; use the `100.x` IP temporarily. |
| `Permission denied (publickey)` (pikpik → Linux) | pikpik's pubkey isn't in that host's `ssh.nix`, or the host wasn't rebuilt. |
| `Permission denied (publickey)` (Linux → pikpik) | The host's key is missing from `users.users.<user>.openssh.authorizedKeys.keys` in `configuration.nix`, or the Mac has not rebuilt since — see §10. Password auth is disabled. |
| `Connection refused` on port 2222 | The NixOS host lacks `./ssh.nix` in `configuration.nix`, or the firewall/rebuild didn't apply. |
| `ssh olimar` ignores the config | The `Include config.d/*` line is missing from the top of `~/.ssh/config` (see §9). Run `./scripts/ssh-setup pikpik`; it prepends the include and warns if the drop-in still isn't applied. |
| `Bad configuration option: UseKeychain` | You're running nixpkgs `openssh`, which shadows `/usr/bin/ssh`; it is deliberately not installed. |
| Key passphrase asked every time | `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`, and keep `UseKeychain yes`. |
| `fish: Unknown command: tailscale` | The shared fish config only defines the `tailscale` function when `/Applications/Tailscale.app` exists. Install the cask (`tailscale-app`), then `exec fish`. |
| New terminal still starts zsh | `~/.zshrc` is not linked (dotbot will not replace a regular file). `ls -l ~/.zshrc`, move an existing file aside, then `./scripts/link pikpik` — see §4. |
| fish aliases/prompt missing | fish is not the login shell — see §4. |
| Ghostty hotkey does nothing | Grant Ghostty Accessibility permission; re-toggle it after an app update. |
| `darwin-rebuild: command not found` | The first bootstrap didn't finish — re-run `./scripts/install pikpik`. |
| `Some links were not successfully set up` | dotbot will not overwrite a regular file. Move it aside and re-run `./scripts/link pikpik` (see §3). |
| `dotbot is not installed` / `dotbot: command not found` | `dotbot` comes from the system profile, which only exists after `./scripts/install pikpik`. `scripts/link` also finds it in the profile dirs (stale `PATH`) and falls back to `nix run nixpkgs#dotbot`, so pulling latest is usually enough. |
| `chsh: /run/current-system/sw/bin/fish: non-standard shell` | The first `darwin-rebuild` has not run yet, so fish is not in `/etc/shells`. |
| `primary user ... does not exist, aborting activation` | `system.primaryUser` in `nixos/configuration.nix` must match `whoami` — nix-darwin checks it with `id` at activation. |
| `Using the homebrew module requires homebrew installed` | Install Homebrew (§2) — nix-darwin only drives an existing `brew`. `scripts/install` checks this before building. |
| `command not found` after emptying the old profile | Your login shell was `~/.nix-profile/bin/fish` — recover with `chsh -s /bin/zsh`, redo §4, then §12. |

## Notes

- **Old `nix profile` leftovers:** before the migration pikpik used `nix profile`.
  nix-darwin keeps `$HOME/.nix-profile` first in `PATH`, so those entries shadow
  the system packages until you empty it — see §12.
- **Two nixpkgs inputs:** the system tracks `nixpkgs-26.05-darwin` (the macOS
  release branch: same packages as `nixos-26.05` plus Darwin fixes), while
  `nixpkgs-unstable` supplies only `claude-code` and `herdr`. Running
  `./scripts/update pikpik` moves both.
- **Mosh:** `mosh olimar` works (olimar enables `programs.mosh`). louie does not
  yet — use plain `ssh louie`, or add `programs.mosh.enable = true;` to
  `nixos/hosts/louie/packages.nix`.
- **No git config linked:** the shared `~/.gitconfig` uses a personal identity.
  Create `profiles/pikpik/gitconfig` with your work name/email and link it.
- **fish universal variables are not linked:** `fish_variables` is per-machine
  state that fish rewrites, so it is gitignored instead of tracked.
- **`git` and `curl` come from Nix**, so they shadow `/usr/bin/git` and
  `/usr/bin/curl`. Nix's git ships the Keychain credential helper, so HTTPS auth
  works; if corporate tooling insists on the Xcode shim, drop `git`/`curl` from
  `packages.nix`.
- **No Zed config linked:** `profiles/shared/zed/` hardcodes a NixOS fish path;
  a macOS Zed config needs its own copy.
- **Backups:** exclude `/nix` from Time Machine — it is reproducible and large.
- **Tailscale key expiry:** personal tailnets expire device keys (180 days by
  default). Disable expiry for pikpik in the admin console if that's annoying.
- **Not managed by Nix:** App Store apps, FileVault, and anything else behind a
  System Settings UI. `system.defaults.CustomUserPreferences` covers extra
  `defaults write` keys.
