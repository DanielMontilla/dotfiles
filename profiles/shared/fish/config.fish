# Use nixpkgs/prebuilt Zed (not flatpak). Guarded because macOS profiles may
# provide Zed as an .app whose CLI is `zed`, not `zeditor`.
if type -q zeditor
    function zed --description 'Zed editor'
        command zeditor $argv &
    end
end

# Tailscale on macOS keeps its CLI inside the app bundle. The pkg also links
# /usr/local/bin/tailscale, but fish never reads /etc/paths, so that path is
# often not on PATH. Point at the bundle directly; guarded so Linux profiles
# are unaffected. (The GUI is still what owns the tunnel/Network Extension —
# this only makes `tailscale status`/`up`/`ping` work from a terminal.)
if test -x /Applications/Tailscale.app/Contents/MacOS/Tailscale
    function tailscale --description 'Tailscale CLI (macOS app bundle)'
        /Applications/Tailscale.app/Contents/MacOS/Tailscale $argv
    end
end

# On macOS the account's login shell stays /bin/zsh and profiles/pikpik/zshrc
# execs fish (nix-darwin cannot change an account it did not create). Make
# $SHELL agree, so tools that spawn "$SHELL" (e.g. `nd`) get fish, not zsh.
if test (uname) = Darwin; and test -x /run/current-system/sw/bin/fish
    set -gx SHELL /run/current-system/sw/bin/fish
end

# Herdr starts the remote server over SSH, so panes inherit SSH_CONNECTION from
# that bootstrap session. Starship keys off SSH_CONNECTION and draws the
# host/SSH indicator even though you're in a Herdr pane, not a raw SSH shell.
# Drop the connection-identity vars inside Herdr panes; keep SSH_AUTH_SOCK so
# git/ssh agent forwarding still works.
if set -q HERDR_ENV
    set -e SSH_CONNECTION SSH_CLIENT SSH_TTY
end

starship init fish | source

fish_add_path $HOME/.local/bin

# nd: `nix develop` that drops into the current shell ($SHELL) instead of the
# default bash, so aliases, prompt, and direnv carry into the dev shell.
alias nd='nix develop -c $SHELL'

# Warm the persistent Herdr server from the first graphical terminal, so
# `herdr --remote` attaches to a running server with the desktop session
# environment instead of cold-bootstrapping one over SSH (which inherits
# SSH_CONNECTION and takes longer to become interactive). Interactive shells
# only, and never inside a Herdr pane, so panes can't recurse.
if status is-interactive; and not set -q HERDR_ENV; and type -q herdr
    if set -q WAYLAND_DISPLAY; or set -q DISPLAY
        if not test -S $HOME/.config/herdr/herdr.sock
            command nohup herdr server >/dev/null 2>&1 &
            disown $last_pid
        end
    end
end
