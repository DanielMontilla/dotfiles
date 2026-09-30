# louie-specific fish configuration

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

# eza: modern, maintained replacement for ls
# Defined in the user config.fish (sourced last) so it overrides the
# NixOS-generated `alias ls 'ls --color=tty'` in /etc/fish/config.fish,
# which fish sources before this file.
# Reference: https://eza.rocks/ (flags below verified against the docs)
if command -v eza >/dev/null
    # Tree view, one level deep, with icons and directories grouped first.
    alias ls='eza --icons=auto --tree --level=1 --group-directories-first'

    # Long listing with a header, group column, git status and grouped dirs.
    alias ll='eza --icons=auto --long --group --header --git --group-directories-first'

    # Long listing including hidden files.
    alias la='eza --icons=auto --long --all --group --header --git --group-directories-first'

    # Tree view, two levels deep, directories first.
    alias lt='eza --icons=auto --tree --level=2 --group-directories-first'
end

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
