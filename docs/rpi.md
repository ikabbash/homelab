# Raspberry Pi
Homelab's Raspberry Pi runs Pi-hole for network-wide ad blocking and Tailscale for remote access, both installed directly on Raspberry Pi OS. Reference: [Tailscale's guide](https://tailscale.com/docs/solutions/block-ads-all-devices-anywhere-using-raspberry-pi).

## Pi-hole
Update the Pi, then install:
```bash
sudo apt update && sudo apt upgrade -y
curl -sSL https://install.pi-hole.net | bash
```

The Pi needs a static IP reserved on the DHCP server before running the installer.

During setup:
- **Static IP prompt**: confirm the address already reserved.
- **Upstream DNS**: Quad9 also filters malicious domains; Cloudflare is generally fastest.
- **Blocklist**: accept the Steven Black unified hosts list; add more later (OISD, AdGuard) under Group Management > Adlists.
- **Web Admin Interface + Web Server**: enable both.
- **Query logging**: enable for visibility into blocked/requested domains, disable later to minimize logs.
- **Privacy mode**: "Show everything" is fine for home use.

Set the admin password:
```bash
pihole setpassword
```

Tailscale traffic hits Pi-hole over its network interface rather than loopback, so DNS needs to listen beyond localhost: Settings → DNS → Expert mode → Interface settings → Permit all origins.

### DNS records
For homelab-internal DNS, use custom dnsmasq lines under Settings → All settings → Miscellaneous → dnsmasq_lines. Pi-hole persists these in `pihole.toml`, so they survive restarts and updates.

```
address=/homelab.example.com/192.168.1.10
address=/vault.homelab.example.com/192.168.1.11
address=/pi-hole.homelab.example.com/192.168.1.12
```

Or via CLI:

```bash
pihole-FTL --config misc.dnsmasq_lines '["address=/homelab.example.com/192.168.1.10","address=/vault.homelab.example.com/192.168.1.11","address=/pi-hole.homelab.example.com/192.168.1.12"]'
sudo systemctl restart pihole-FTL
```

### Access control
Restrict the admin UI to trusted IPs via Settings → All Settings → Webserver and API → webserver.acl, or via CLI:
```bash
pihole-FTL --config webserver.acl '-0.0.0.0/0,+127.0.0.1,+<RPI-IP>,+<IP1>,+<IP2>,+<IP-N>'
```

Ordering matters, a wrong rule can lock you out. If it happens, SSH in and reset:
```bash
pihole-FTL --config webserver.acl ''
```

### HTTPS
HTTPs and cert creation is enabled using `certbot`, with Cloudflare as the DNS provider for cert issuance:
```bash
sudo apt install certbot python3-certbot-dns
```

Create a Cloudflare API token with `Zone - DNS - Edit` and `Zone - Zone - Read`, then store it:
```bash
sudo mkdir -p /etc/letsencrypt/cloudflare
sudo echo "dns_cloudflare_api_token = your-token" > /etc/letsencrypt/cloudflare/creds.ini
sudo chmod 600 /etc/letsencrypt/cloudflare/creds.ini
```

A deploy hook combines the renewed cert with the private key into the pem Pi-hole expects, restarts `pihole-FTL`, and pings [healthchecks.io](https://healthchecks.io/) on success or failure so a broken renewal doesn't go unnoticed:
```bash
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo tee /etc/letsencrypt/renewal-hooks/deploy/pihole-cert.sh > /dev/null << 'EOF'
#!/bin/bash
set -euo pipefail

PIHOLE_PEM="/etc/pihole/tls.pem"
HEALTHCHECKS_URL="https://hc-ping.com/your-check-uuid-here"

trap 'curl -fsS -m 10 --retry 3 "${HEALTHCHECKS_URL}/fail" > /dev/null 2>&1 || true' ERR

if [[ -z "${RENEWED_LINEAGE:-}" ]]; then
  echo "ERROR: RENEWED_LINEAGE not set. This script must be run by certbot as a deploy hook." >&2
  exit 1
fi

FULLCHAIN="${RENEWED_LINEAGE}/fullchain.pem"
PRIVKEY="${RENEWED_LINEAGE}/privkey.pem"

TMP_PEM="$(mktemp)"
cat "$FULLCHAIN" "$PRIVKEY" > "$TMP_PEM"
install -o root -g root -m 600 "$TMP_PEM" "$PIHOLE_PEM"
rm -f "$TMP_PEM"

systemctl restart pihole-FTL
curl -fsS -m 10 --retry 3 "${HEALTHCHECKS_URL}" > /dev/null 2>&1 || true
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/pihole-cert.sh
```

Point Pi-hole at the cert the hook writes:
```bash
pihole-FTL --config webserver.tls.cert '/etc/pihole/tls.pem'
```

Request the certificate:
```bash
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare/creds.ini \
  -d pi-hole.example.com \
  --deploy-hook /etc/letsencrypt/renewal-hooks/deploy/pihole-cert.sh
```

Confirm at `https://pi-hole.example.com/admin`, and verify renewal works with `sudo certbot renew --dry-run`.

## Tailscale
Install and enable IP forwarding:
```bash
curl -fsSL https://tailscale.com/install.sh | sh

echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Bring the node up, advertising only the specific IPs that should be reachable over the tailnet:
```bash
sudo tailscale up --accept-dns=false --advertise-routes=rpi-ip/32,control-plane-ip/32,gateway-ip/32,vault-gateway-ip/32
```

Approve each `/32` route from the admin console: Machines → the Pi → route/subnet icon → enable.

Set Pi-hole as the tailnet's DNS server: Tailscale admin console → DNS → Add nameserver → Custom → enter the Pi's IP → enable Override DNS servers.