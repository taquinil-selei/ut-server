#!/usr/bin/env bash
# Writes /opt/ut2004/.env (only if absent) and builds and starts the server.
# Usage: 03-configure-start.sh 'Server name'   (ASCII letters, digits, space . _ - ; max 40 characters)
# The first build takes minutes (apt, patch download): run it in the background and poll
# until the last line starts with "RESULT:".
set -euo pipefail
trap 'rc=$?; [ "$rc" -eq 0 ] || echo "RESULT: FAIL (exit $rc)"' EXIT

cd /opt/ut2004
NAME=${1:-UT2004 Server}
if ! [[ "$NAME" =~ ^[A-Za-z0-9\ ._-]{1,40}$ ]]; then
  echo "FAIL  server name must be 1-40 characters of A-Z a-z 0-9 space . _ -"
  exit 1
fi

if [ ! -f .env ]; then
  pw=$(openssl rand -hex 16)
  umask 077
  cat > .env <<ENV
SERVER_NAME=$NAME
ADMIN_PASSWORD=$pw
GAME_PASSWORD=
MAX_PLAYERS=16
START_MAP=DM-Rankin
GAME_TYPE=XGame.xDeathMatch
WEBADMIN=false
WEBADMIN_PORT=8075
EXTRA_ARGS=
ENV
  echo "Created .env with a generated ADMIN_PASSWORD"
else
  echo ".env already exists, left untouched ($(grep '^SERVER_NAME=' .env))"
  [ "$(grep '^SERVER_NAME=' .env | cut -d= -f2-)" = "$NAME" ] || echo "NOTE  requested name differs from SERVER_NAME in .env; not changed"
fi

docker compose up -d --build
docker compose ps
echo "RESULT: STARTED"
