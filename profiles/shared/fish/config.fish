# use nixpkgs zed (not flatpak)
function zed --description 'Zed editor'
    command zeditor $argv & 
end

starship init fish | source

fish_add_path $HOME/.local/bin
