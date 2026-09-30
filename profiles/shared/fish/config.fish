# use nixpkgs zed (not flatpak)
function zed --description 'Zed editor'
    command zeditor $argv & 
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
