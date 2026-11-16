---
name: setup-host
description: Install the Macro Deck 3 host on Linux (APT repo), open its ports, and connect a phone or browser as the deck. Use on "install Macro Deck", "set up the macropad".
---

# Set up the Macro Deck host

Macro Deck 3 (stable since 3.0.0, 2026-10-31) runs on the computer being controlled. Phones, tablets and browsers are only
displays that send button presses. The old Macro Deck 2 Android app (IzzyOnDroid, 2.4.1-beta, 2022) talks only to the
Windows-only v2 server; it does not work with a Linux host. Tell the user to remove it if they have it.

## 1. Install (Debian/Ubuntu, amd64 only)

Use the APT repo so updates arrive with `apt upgrade` (a loose `.deb` does not update):

```bash
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSLo /etc/apt/keyrings/macro-deck.asc https://packages.macro-deck.app/gpg.asc
sudo tee /etc/apt/sources.list.d/macro-deck.sources > /dev/null <<'EOF'
Types: deb
URIs: https://packages.macro-deck.app
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/macro-deck.asc
EOF
sudo apt-get update && sudo apt-get install -y macro-deck
```

`apt-cache policy macro-deck` must show a candidate from `stable`. If it is empty, use `Suites: beta` (beta also carries
stable releases). Fedora: the `.rpm`; Arch and others: the AppImage, both from
https://github.com/Macro-Deck-App/Macro-Deck/releases.

## 2. Start and check

Launch it once from the app menu (desktop entry `Macro Deck`) so it creates its data folder
(`${XDG_DATA_HOME:-$HOME/.local/share}/MacroDeck`), then check the host is listening:

```bash
ss -ltnp | grep -E ':819[34]'                         # 8193 HTTP, 8194 HTTPS by default
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8193/   # 200
```

The ports in use are in Settings → Network. If the port was taken, Macro Deck starts without it.

## 3. Firewall

If `ufw` is active, open the ports to the local network only (and the tailnet if the user has Tailscale), never to any:

```bash
LAN=$(ip -4 route | awk '/proto kernel/ && !/docker|virbr|tailscale/ {print $1; exit}')
for p in 8193 8194; do
  sudo ufw allow from "$LAN" to any port $p proto tcp comment 'Macro Deck'
  ip link show tailscale0 >/dev/null 2>&1 && sudo ufw allow in on tailscale0 to any port $p proto tcp comment 'Macro Deck'
done
```

## 4. Connect the phone

- **Free:** open `http://<host LAN IP>:8193` in the phone's browser and add it to the home screen.
- **Companion app** (Android/iOS): free download, one-time in-app licence after a 7-day trial. Add the host by IP and port.

Report the URLs the user should use (`ip -4 -br a`).

## Linux caveats to tell the user (once)

- **Wayland:** keyboard, mouse and focused-app features work only through XWayland. Native Wayland apps may not receive
  simulated keys. Prefer buttons that call a command or an HTTP endpoint over buttons that send keystrokes.
- **Screen lock:** actions are blocked while locked only if the desktop reports the lock to systemd-logind (GNOME and KDE do).

Next: `connect-mcp` so the agent can build decks.
