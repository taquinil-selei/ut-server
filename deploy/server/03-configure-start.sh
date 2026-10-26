#!/usr/bin/env bash
# Writes /opt/ut2004/.env (only if absent) and builds and starts the server.
# Usage: 03-configure-start.sh 'Server name'   (no " #" or "$" in the name: compose reads them specially)
# The first build takes minutes (apt, patch download): run it in the background and poll for "RESULT:".
set -euo pipefail
trap 'rc=$?; [ "$rc" -eq 0 ] || echo "RESULT: FAIL (exit $rc)"' EXIT

cd /opt/ut2004
NAME=${1:-UT2004 Server}

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
  echo "Created .env with a generated ADMIN_PASSWORD (read it on the server: grep ADMIN_PASSWORD /opt/ut2004/.env)"
else
  echo ".env already exists, left untouched"
fi

docker compose up -d --build
docker compose ps
echo "RESULT: STARTED (now run 04-verify.sh)"
