set fish_greeting

# Set LOCALE_ARCHIVE for Nix packages to use UTF-8 locales from glibcLocales
# Checks user profile first, then falls back to system default profile
if test -f ~/.nix-profile/lib/locale/locale-archive
  set -gx LOCALE_ARCHIVE ~/.nix-profile/lib/locale/locale-archive
else
  if test -f /nix/var/nix/profiles/default/lib/locale/locale-archive
    set -gx LOCALE_ARCHIVE /nix/var/nix/profiles/default/lib/locale/locale-archive
  end
end

# Starship setup
starship init fish | source
:
