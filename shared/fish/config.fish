set fish_greeting

# Functions
function ls --wraps eza --description 'alias ls=eza'
  eza --icons --group-directories-first $argv
end

# Starship setup
starship init fish | source
