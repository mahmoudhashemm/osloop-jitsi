# OSLOOP Jitsi Meet - quick install

Needs `docker`, `docker compose`, `curl`, `openssl`. One command:

```bash
curl -s -H "Authorization: token YOUR_TOKEN" https://raw.githubusercontent.com/mahmoudhashemm/osloop-jitsi/main/run.sh | sudo bash -s meet.example.com 203.0.113.10
```

Arguments: `DOMAIN` `PUBLIC_IP` [`FOLDER=/opt/jitsi`] [`HTTP_PORT=8000`].

What it does: downloads the official Jitsi docker release `stable-11509`, turns on JWT host sign-in
(guests allowed), pulls the OSLOOP images `mahmoudhashemm/osloop-jitsi-web:20261120` (branding) and
`mahmoudhashemm/osloop-jitsi-prosody:20261120` (room-password + auto-lobby plugins), generates all passwords and the token secret, starts the stack,
and prints the values to enter in Odoo (Settings > Jitsi Meet). The secret is also in `FOLDER/JWT_SECRET.txt` (mode 600).

Afterwards: point your HTTPS reverse proxy or tunnel at `http://127.0.0.1:HTTP_PORT` and open UDP 10000.
Rotate the secret later with the command shown in the Odoo popup (`Generate new token secret`).

The GitHub repo is private, so the one-liner needs a token (create a fine-grained token with read access to this repo only):

```bash
curl -s -H "Authorization: token YOUR_TOKEN" https://raw.githubusercontent.com/mahmoudhashemm/osloop-jitsi/main/run.sh | sudo bash -s meet.example.com 203.0.113.10
```

The Docker Hub images are public (they contain no secrets), so the servers need no Docker login.

## Copyright
Copyright (c) 2026 OSLOOP. All rights reserved.
