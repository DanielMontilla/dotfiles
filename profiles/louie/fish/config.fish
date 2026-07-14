# louie-specific fish configuration

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
