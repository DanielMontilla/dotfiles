# Use nixpkgs/prebuilt Zed (not flatpak). Guarded because macOS profiles may
# provide Zed as an .app whose CLI is `zed`, not `zeditor`.
if type -q zeditor
    function zed --description 'Zed editor'
        command zeditor $argv &
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

# eza is the maintained successor to exa; keep familiar ls commands with a
# compact, directory-first listing and richer variants for detail/tree views.
if type -q eza
    alias ls='eza --icons=auto --tree --level=1 --group-directories-first'
    alias ll='eza --icons=auto --long --group --header --git --group-directories-first'
    alias la='eza --icons=auto --long --all --group --header --git --group-directories-first'
    alias lt='eza --icons=auto --tree --level=2 --group-directories-first'
end

# Yazi's shell wrapper changes the current directory to the last visited one.
if type -q yazi
    function y --description 'Open Yazi and change to its last directory'
        set -l tmp (mktemp -t yazi-cwd.XXXXXX)
        yazi $argv --cwd-file="$tmp"
        set -l cwd (cat -- "$tmp")
        if test -n "$cwd"; and test "$cwd" != "$PWD"; and test -d "$cwd"
            cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
end

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
