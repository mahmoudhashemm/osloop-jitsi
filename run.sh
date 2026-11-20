#!/bin/bash
# OSLOOP Jitsi Meet quick install (JWT host sign-in + per-meeting password + auto lobby).
# Usage: sudo bash run.sh DOMAIN PUBLIC_IP [FOLDER=/opt/jitsi] [HTTP_PORT=8000]
# Example: curl -s https://raw.githubusercontent.com/mahmoudhashemm/osloop-jitsi/main/run.sh | sudo bash -s meet.example.com 203.0.113.10
# Needs docker + docker compose + curl + openssl. HTTPS is NOT done here: point your reverse proxy
# (nginx / cloudflared) at http://127.0.0.1:HTTP_PORT. Open UDP 10000 on the firewall (media).
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 DOMAIN PUBLIC_IP [FOLDER=/opt/jitsi] [HTTP_PORT=8000]"
  exit 1
fi
DOMAIN="$1"
PUBLIC_IP="$2"
DEST="${3:-/opt/jitsi}"
HTTP_PORT="${4:-8000}"
TAG="stable-11509"
WEB_IMAGE="mahmoudhashemm/osloop-jitsi-web:20261120"
PROSODY_IMAGE="mahmoudhashemm/osloop-jitsi-prosody:20261120"

for c in docker curl openssl tar; do
  command -v "$c" >/dev/null || { echo "Missing: $c"; exit 1; }
done
docker compose version >/dev/null || { echo "Missing: docker compose plugin"; exit 1; }
[ -e "$DEST/.env" ] && { echo "$DEST/.env already exists - refusing to overwrite."; exit 1; }

# 1) official Jitsi docker release
mkdir -p "$DEST"
curl -fsSL "https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/${TAG}.tar.gz" | tar xz --strip-components=1 -C "$DEST"
cd "$DEST"

# 2) environment
cp env.example .env
bash ./gen-passwords.sh >/dev/null
SECRET="$(openssl rand -base64 54 | tr -d '\n=+/' | cut -c1-48)"
set_env() { sed -i "s|^#\? \?$1=.*|$1=$2|" .env; grep -q "^$1=" .env || echo "$1=$2" >> .env; }
set_env CONFIG "$DEST/config"
set_env HTTP_PORT "$HTTP_PORT"
set_env PUBLIC_URL "https://$DOMAIN"
set_env JVB_ADVERTISE_IPS "$PUBLIC_IP"
set_env ENABLE_AUTH 1
set_env ENABLE_GUESTS 1
set_env AUTH_TYPE jwt
set_env DISABLE_HTTPS 1
set_env ENABLE_HTTP_REDIRECT 0
set_env ENABLE_AUTO_OWNER 0
set_env JWT_APP_ID osloop-odoo
set_env JWT_ACCEPTED_ISSUERS osloop-odoo
set_env JWT_ACCEPTED_AUDIENCES jitsi
set_env XMPP_MUC_MODULES osloop_auto_lobby,osloop_room_password
set_env JWT_APP_SECRET "$SECRET"
printf %s "$SECRET" > JWT_SECRET.txt
chmod 600 JWT_SECRET.txt .env

# 3) web port only on localhost (the reverse proxy reaches it there)
sed -i "s|- '\${HTTP_PORT}:8000'|- '127.0.0.1:\${HTTP_PORT}:8000'|; s|- '\${HTTPS_PORT}:8443'|- '127.0.0.1:\${HTTPS_PORT}:8443'|" docker-compose.yml

# 4) OSLOOP images from Docker Hub: prosody (room-password + auto-lobby plugins) and web (branding).
# The official compose mounts an empty plugins folder over the image one, so that mount is removed.
sed -i '\#prosody-plugins-custom:/prosody-plugins-custom#d' docker-compose.yml
cat > docker-compose.override.yml <<EOF
services:
    web:
        image: $WEB_IMAGE
        cpus: 1
        mem_limit: 512m
    prosody:
        image: $PROSODY_IMAGE
        cpus: 1
        mem_limit: 1g
    jicofo:
        cpus: 1
        mem_limit: 1g
    jvb:
        cpus: 3
        mem_limit: 3g
EOF
docker compose pull web prosody

[ "${DRY_RUN:-0}" = "1" ] && { echo "DRY_RUN: stopped before start."; exit 0; }

# 5) start
docker compose up -d

cat <<EOF

=== Jitsi is up (local http://127.0.0.1:$HTTP_PORT) ===
Point your HTTPS reverse proxy / tunnel at it, open UDP 10000.
In Odoo (osloop_jitsi_meet) Settings > Jitsi Meet:
  server address : https://$DOMAIN
  token issuer   : osloop-odoo
  token subject  : $DOMAIN   (the XMPP domain, usually meet.jitsi)
  token secret   : $SECRET
(also kept in $DEST/JWT_SECRET.txt, mode 600)
EOF
