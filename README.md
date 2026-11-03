# Pi-hole stack

Network-wide ad blocking on a Raspberry Pi (or any Linux box) with Docker
Compose. One container, one bind mount, one secret.

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | The stack. Pi-hole on ports 53 (DNS) and 8081 (web UI). |
| `.env.example` | Copy to `.env` and fill in. |
| `backup-teleporter.sh` | Exports a Teleporter zip from the running container. |

## Setup

1. **Free up port 53 on the host.** Most Debian/Ubuntu/Raspberry Pi OS images
   run `systemd-resolved` with a stub listener on `127.0.0.53:53`. Pi-hole
   needs the real port. Either disable the stub:

   ```bash
   sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
   sudo systemctl restart systemd-resolved
   ```

   or stop/disable `systemd-resolved` entirely and set `/etc/resolv.conf` by
   hand. Check with `sudo ss -lunp | grep :53` before deploying.

2. **Give the Pi a fixed address.** Either a DHCP reservation on the router
   or a static address on the Pi. Clients will point at this address for
   DNS, so it must not change.

3. **Deploy.**

   ```bash
   cp .env.example .env   # set PIHOLE_PASSWORD
   docker compose up -d
   ```

   Web UI: `http://<pi-ip>:8081/admin`.

   If you use Portainer, add this folder as a git stack and enter the
   `.env` values as stack environment variables instead of a `.env` file.

4. **Point the LAN at it.** On the router, set the DHCP-handed-out DNS server
   to the Pi's address (and only the Pi; a second public resolver as
   "backup" lets clients bypass blocking at random). Renew leases on a client
   and confirm `nslookup doubleclick.net` returns `0.0.0.0`.

## Lesson learned: the host must not use its own Pi-hole

Leave the Pi itself pointed at public DNS (Cloudflare, Quad9, whatever). If
the host resolves through its own container, it cannot resolve anything,
including the registry pull for the Pi-hole image, until that container is
up. That is a boot-time deadlock that is very confusing the first time it
bites. LAN clients use the Pi-hole; the host is exempt.

On Raspberry Pi OS with NetworkManager, a drop-in like this keeps the host on
public DNS no matter what DHCP says:

```ini
# /etc/NetworkManager/conf.d/98-host-dns-policy.conf
[global-dns-domain-*]
servers=1.1.1.1,8.8.8.8
```

## Backups

Everything Pi-hole knows is in the bind-mounted config directory. Two layers:

- **Teleporter zip** (portable, versions-tolerant): run
  `./backup-teleporter.sh /path/on/other/disk` from cron or a systemd timer.
  Restore from the web UI under Settings -> Teleporter.
- **The config directory itself** (exact state): tar it up with the rest of
  your service configs. Restore by dropping it back in place before
  `docker compose up`.

Back up to different physical media than the boot disk. An SD card that dies
takes its own backups with it.

## Upgrading

`docker compose pull && docker compose up -d`. Pi-hole v6 uses the
`FTLCONF_*` environment names in the compose file; if you are coming from v5
notes online, the old `WEBPASSWORD`/`PIHOLE_DNS_` names no longer apply.
