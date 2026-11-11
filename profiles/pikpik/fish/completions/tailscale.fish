# Static completions for the Tailscale CLI.
#
# This shadows the vendor file of the same name (fish searches
# ~/.config/fish/completions first). The vendor file is Cobra-generated and runs
# this at *load* time:
#
#   if type -q tailscale
#       complete --do-complete "tailscale " > /dev/null 2>&1
#   end
#
# Fish autoloads a command's completion file as soon as you type the command
# and a space, so that line executes the CLI before you press Enter. On macOS
# the app bundle binary decides at startup whether to be the GUI or the CLI,
# and under fish it can pick the GUI — the terminal then waits on a windowed
# process and looks frozen. Typing `tailscale ` is enough to trigger it.
#
# Keeping this file inert at load time avoids that entirely.

complete -c tailscale -f

complete -c tailscale -n '__fish_use_subcommand' -a 'up down status login logout ip netcheck ping version whoami serve funnel ssh file cert dns lock set get bugreport switch update wait web metrics drive exit-node appc-routes syspolicy service configure completion'
