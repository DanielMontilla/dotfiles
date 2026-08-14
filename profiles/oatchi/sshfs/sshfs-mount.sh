#!/usr/bin/env bash
#
# Wrapper for the oatchi sshfs mount. Connection details are passed explicitly
# (not via ~/.ssh/config) because OpenSSH refuses a config file owned by
# another user, so root would ignore the `olimar` alias. Edit the command below
# to change what's mounted, then re-run `scripts/sshfs-mount install`.

exec /home/daniel/.nix-profile/bin/sshfs -f \
    -o reconnect,allow_other,ServerAliveInterval=15,ServerAliveCountMax=3,uid=1000,gid=1000 \
    -o port=2222 \
    -o ssh_command='/home/daniel/.nix-profile/bin/ssh -i /home/daniel/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new' \
    daniel@100.90.98.83:/home/daniel \
    /home/daniel/olimar
