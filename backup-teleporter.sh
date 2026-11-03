#!/usr/bin/env bash
# backup-teleporter.sh — export a Pi-hole "Teleporter" zip from the running
# container. Teleporter is the canonical portable backup: adlists, domains,
# groups, clients and settings in one file you can re-import from the web UI
# (Settings -> Teleporter) on any fresh Pi-hole, same version or newer.
#
# Usage: backup-teleporter.sh [dest-dir]   (default: ./backups)
set -euo pipefail

DEST="${1:-./backups}"
STAMP="$(date +%F)"
mkdir -p "$DEST"

docker exec pihole sh -c 'rm -f /tmp/*teleporter*.zip && cd /tmp && pihole-FTL --teleporter >/dev/null 2>&1'
ZIP="$(docker exec pihole sh -c 'ls /tmp/*teleporter*.zip' | tr -d '\r')"
docker cp "pihole:$ZIP" "$DEST/pihole-teleporter-$STAMP.zip"
echo "wrote $DEST/pihole-teleporter-$STAMP.zip"

# Keep the last 14.
ls -1t "$DEST"/pihole-teleporter-*.zip | tail -n +15 | xargs -r rm -f
