set fish_greeting

# Functions
function ls --wraps eza --description 'alias ls=eza'
  eza --icons --group-directories-first $argv
end

function zj --wraps zellij --description 'alias zj=zellij with optional layout'
  zellij $argv
end

# Starship setup
starship init fish | source
