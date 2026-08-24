# VPNs on olimar

**Add a new VPN connection. Assumes your provider's `.conf` file is already in `~/vpn/`.**

Time: ~5 minutes.

## Steps

1. **Check the key is real.**
   Open `~/vpn/<name>.conf`. If `PrivateKey` says `<insert_your_private_key_here>`:
   ```bash
   cd ~/vpn
   umask 077
   wg genkey > <name>.key
   wg pubkey < <name>.key > <name>.pub
   ```
   Paste `<name>.key` into the conf, and paste `<name>.pub` where your provider asks for a public key (dashboard → manual WireGuard setup). If the provider gave you a completed conf with a real key, skip this.

2. **Import it into NetworkManager:**
   ```bash
   nmcli connection import type wireguard file ~/vpn/<name>.conf
   ```

3. **Make sure it starts OFF:**
   ```bash
   nmcli connection modify <name> autoconnect no
   ```

4. **Enable it when you want it:** run `wlctl`, press `v`, select the tunnel, press Space. (Same spot disables it.)

5. **Verify:** `curl https://am.i.mullvad.net/ip` — should show the VPN exit IP while on, your real IP while off.

## Notes

- Provider tunnels are NOT declared in nix — NetworkManager keeps them in `/etc/NetworkManager/system-connections/` and they survive rebuilds. Tweak freely in wlctl.
- Exception: infra tunnels with fixed ports or custom routing (like `wg-co-bog`) live in `nixos/hosts/olimar/networking.nix`.
- Two tunnels sharing the same tunnel IP (e.g. both `10.14.x.x`) must never be enabled at the same time.
- Delete a VPN: `wlctl` → `v` → select → `d`.

Next: after step 3, do a quick on/off cycle in wlctl to confirm it connects before you need it.
