#!/usr/bin/env bash
# Prepares /game (patch + ini) and starts the UT2004 dedicated server.
set -euo pipefail

GAME_DIR=${GAME_DIR:-/game}
PATCH=/opt/oldunreal-patch.tar.bz2
PATCH_ID=$(cat /opt/oldunreal-patch.id)
MARKER="$GAME_DIR/.oldunreal-patch-id"

SERVER_NAME=${SERVER_NAME:-UT2004 Server}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-}
GAME_PASSWORD=${GAME_PASSWORD:-}
MAX_PLAYERS=${MAX_PLAYERS:-16}
START_MAP=${START_MAP:-DM-Rankin}
GAME_TYPE=${GAME_TYPE:-XGame.xDeathMatch}
WEBADMIN=${WEBADMIN:-false}
WEBADMIN_PORT=${WEBADMIN_PORT:-8075}
EXTRA_ARGS=${EXTRA_ARGS:-}

die() { echo "ERROR: $*" >&2; exit 1; }

# Sets key=value inside [section] of an ini file; fails if the section is absent.
# The value travels through the environment so awk never interprets backslashes.
ini_set() {
  local file=$1 section=$2 key=$3 tmp
  tmp=$(mktemp)
  INI_VALUE=$4 awk -v sec="[$section]" -v key="$key" '
    { line = $0; cr = (line ~ /\r$/) ? "\r" : ""; sub(/\r$/, "", line) }
    line ~ /^\[/ {
      if (in_sec && !done) { print key "=" ENVIRON["INI_VALUE"] eol; done = 1 }
      in_sec = (line == sec); if (in_sec) { seen = 1; eol = cr }
    }
    in_sec && index(line, key "=") == 1 {
      if (!done) { print key "=" ENVIRON["INI_VALUE"] cr; done = 1 }
      next
    }
    { print }
    END {
      if (in_sec && !done) print key "=" ENVIRON["INI_VALUE"] eol
      if (!seen) exit 3
    }
  ' "$file" > "$tmp" || { rm -f "$tmp"; die "ini section [$section] not found in $file"; }
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

[ "$(uname -m)" = "x86_64" ] || die "this image supports x86_64 only (got $(uname -m))"
[ -d "$GAME_DIR" ] && [ -w "$GAME_DIR" ] || die "$GAME_DIR is missing or not writable for uid $(id -u) (chown it to that uid)"

# Content directories come from an owned copy of the game (see docs/game-files.md).
missing=()
for d in Animations KarmaData Maps Music Prefabs Sounds Speech StaticMeshes Textures; do
  [ -d "$GAME_DIR/$d" ] || missing+=("$d")
done
[ ${#missing[@]} -eq 0 ] || die "game content missing in $GAME_DIR: ${missing[*]} (see docs/game-files.md)"

if [ "$(cat "$MARKER" 2>/dev/null || true)" != "$PATCH_ID" ]; then
  # A System/ copied from the original game media breaks the patched server.
  [ ! -e "$GAME_DIR/System" ] || [ -e "$MARKER" ] \
    || die "$GAME_DIR/System exists but was not created by this image; delete it and copy only the content directories"
  echo "Installing OldUnreal patch ${PATCH_ID:0:12} into $GAME_DIR"
  tar -xjf "$PATCH" -C "$GAME_DIR"
  echo "$PATCH_ID" > "$MARKER"
fi

cd "$GAME_DIR/System"
export LD_LIBRARY_PATH=".${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [ ! -f UT2004.ini ]; then
  echo "Creating UT2004.ini from Default.ini"
  cp Default.ini UT2004.ini
  [ ! -f DefUser.ini ] || cp DefUser.ini User.ini
fi

ini_set UT2004.ini Engine.GameReplicationInfo ServerName "$SERVER_NAME"
ini_set UT2004.ini Engine.GameReplicationInfo ShortName "$SERVER_NAME"
ini_set UT2004.ini Engine.AccessControl AdminPassword "$ADMIN_PASSWORD"
ini_set UT2004.ini Engine.AccessControl GamePassword "$GAME_PASSWORD"

case "$WEBADMIN" in
  true)
    [ -n "$ADMIN_PASSWORD" ] || die "WEBADMIN=true requires ADMIN_PASSWORD"
    ini_set UT2004.ini UWeb.WebServer bEnabled True
    ini_set UT2004.ini UWeb.WebServer ListenPort "$WEBADMIN_PORT" ;;
  false) ini_set UT2004.ini UWeb.WebServer bEnabled False ;;
  *) die "WEBADMIN must be true or false" ;;
esac

# shellcheck disable=SC2086  # EXTRA_ARGS is intentionally word-split
exec ./ucc-bin server "${START_MAP}?game=${GAME_TYPE}?MaxPlayers=${MAX_PLAYERS}" \
  -nohomedir ini=UT2004.ini $EXTRA_ARGS
