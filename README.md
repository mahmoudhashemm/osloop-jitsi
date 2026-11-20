# OSLOOP Jitsi Meet - quick install

Needs `docker`, `docker compose`, `curl`, `openssl`, and a server whose SSH key is linked to the GitHub account `mahmoudhashemm` (the repo is private, no token needed). One command:

```bash
git clone --depth=1 git@github.com:mahmoudhashemm/osloop-jitsi.git /tmp/osloop-jitsi && sudo bash /tmp/osloop-jitsi/run.sh meet.example.com 203.0.113.10

```

Arguments: `DOMAIN` `PUBLIC_IP` [`FOLDER=/opt/jitsi`] [`HTTP_PORT=8000`]. Everything is installed under `FOLDER` (default `/opt/jitsi`).

What it does: downloads the official Jitsi docker release `stable-11509`, turns on JWT host sign-in (guests allowed), pulls the OSLOOP images `mahmoudhashemm/osloop-jitsi-web:20261120` (branding) and `mahmoudhashemm/osloop-jitsi-prosody:20261120` (room-password + auto-lobby plugins), generates all passwords and the token secret, starts the stack, and prints the values to enter in Odoo (Settings > Jitsi Meet). The secret is also in `FOLDER/JWT_SECRET.txt` (mode 600).

Afterwards: point your HTTPS reverse proxy or tunnel at `http://127.0.0.1:HTTP_PORT` and open UDP 10000.
Rotate the secret later with the command shown in the Odoo popup (`Generate new token secret`).
The Docker Hub images are public (no secrets inside), so no Docker login is needed.

## Copyright
Copyright (c) 2026 OSLOOP. All rights reserved.
