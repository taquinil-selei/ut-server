#!/usr/bin/env bash
# Route A from docs/game-files.md: install the game with OldUnreal's installer and
# move the content directories into /opt/ut2004/game. Safe to rerun. Takes
# minutes (3 GB download), so run it in the background and poll its log until
# the last line starts with "RESULT:".
#
# The installer makes you agree to the Epic Games Terms of Service
# (https://legal.epicgames.com/en-US/epicgames/tos). This script answers that
# prompt only when the owner has agreed: set EPIC_TOS_ACCEPTED=yes. Without it,
# run the installer by hand in an interactive session instead.
set -euo pipefail
trap 'rc=$?; [ "$rc" -eq 0 ] || echo "RESULT: FAIL (exit $rc)"' EXIT

GAME=/opt/ut2004/game
INSTALL=/opt/ut2004/install
SCRIPT_URL=https://raw.githubusercontent.com/OldUnreal/FullGameInstallers/master/Linux/install-ut2004.sh
# SCRIPT_SHA256 can be overridden for tests only.
SCRIPT_SHA256=${SCRIPT_SHA256:-ec5f2cd6d9f76ac108487ec8cc751ddd9120771b98402521420ff2df8cb19dad}
DIRS=(Animations KarmaData Maps Music Sounds Speech StaticMeshes Textures)

have_all() { local d; for d in "${DIRS[@]}"; do [ -d "$GAME/$d" ] || return 1; done; }

# One run at a time: a second run would delete the first one's install directory.
exec 9> /run/ut2004-install.lock
flock -n 9 || { echo "FAIL  another run of this script is in progress"; exit 1; }

if have_all; then
  echo "Content already in $GAME, skipping install"
else
  if [ "${EPIC_TOS_ACCEPTED:-}" != yes ]; then
    echo "FAIL  the installer needs the owner's agreement to the Epic Games Terms of Service"
    echo "      (https://legal.epicgames.com/en-US/epicgames/tos). Rerun with EPIC_TOS_ACCEPTED=yes"
    echo "      only after the owner has agreed, or run the installer by hand (docs/game-files.md)."
    exit 1
  fi
  rm -rf "$INSTALL"   # leftovers of an earlier failed run
  cd /root
  curl -fsSL -o install-ut2004.sh "$SCRIPT_URL"
  if ! echo "$SCRIPT_SHA256  install-ut2004.sh" | sha256sum -c -; then
    echo "FAIL  the installer script changed upstream; read it before running it"
    exit 1
  fi
  # The installer reads one character from stdin for the terms prompt.
  printf 'y' | bash install-ut2004.sh -d "$INSTALL" --ui-mode none --application-entry skip --desktop-shortcut skip
  for d in "${DIRS[@]}"; do
    if [ ! -d "$INSTALL/$d" ]; then
      echo "FAIL  installer did not produce $d; contents of $INSTALL:"
      ls "$INSTALL"
      exit 1
    fi
  done
  mkdir -p "$GAME"
  for d in "${DIRS[@]}"; do
    rm -rf "${GAME:?}/$d"   # a partial copy from an earlier failed run
    mv "$INSTALL/$d" "$GAME/"
  done
  rm -rf "$INSTALL"
fi
chown -R 1000:1000 "$GAME"

n=$(ls "$GAME/Maps" | grep -cE 'ONS-(Adara|IslandHop|Tricky|Urban)|BP2' || true)
echo "INFO  bonus-pack maps found: $n (expected 13: 4 ONS-* and 9 *-BP2-*)"
echo "INFO  size: $(du -sh "$GAME" | cut -f1)"
echo "RESULT: PASS"
