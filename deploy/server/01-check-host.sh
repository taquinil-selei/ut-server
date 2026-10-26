#!/usr/bin/env bash
# Read-only check that the host from deploy/hetzner-cloud-init.yaml is ready
# and that the repo files were uploaded to /opt/ut2004. Run as root.
set -uo pipefail
fail=0
ok()  { echo "PASS  $*"; }
bad() { echo "FAIL  $*"; fail=1; }

[ "$(id -u)" -eq 0 ] || { echo "FAIL  run as root"; echo "RESULT: FAIL"; exit 1; }

st=$(cloud-init status --wait 2>&1 | tr '\n' ' ')
case "$st" in
  *"status: done"*) ok "cloud-init: $st" ;;
  *) bad "cloud-init: $st (see /var/log/cloud-init-output.log)" ;;
esac

command -v docker >/dev/null && ok "$(docker --version)" || bad "docker missing"
docker compose version >/dev/null 2>&1 && ok "$(docker compose version)" || bad "docker compose plugin missing"
systemctl is-active --quiet docker && ok "docker daemon active" || bad "docker daemon not active"

ufw_out=$(ufw status 2>&1)
echo "$ufw_out" | grep -q '^Status: active' && ok "ufw active" || bad "ufw not active"
for r in '22/tcp' '7777:7778/udp' '7787/udp'; do
  echo "$ufw_out" | grep -q "^$r " && ok "ufw allows $r" || bad "ufw rule missing: $r"
done

[ -d /opt/ut2004/game ] && ok "/opt/ut2004/game exists" || bad "/opt/ut2004/game missing"
[ "$(stat -c %u /opt/ut2004/game 2>/dev/null)" = 1000 ] && ok "game dir owned by uid 1000" || bad "game dir not owned by uid 1000"

avail_gb=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')
[ "$avail_gb" -ge 25 ] && ok "free disk ${avail_gb} GB" || bad "free disk ${avail_gb} GB (need at least 25)"
echo "INFO  RAM $(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) MB, $(nproc) vCPU, $(. /etc/os-release; echo "$PRETTY_NAME")"

for f in Dockerfile docker-compose.yml .env.example docker/entrypoint.sh deploy/server/02-install-content.sh deploy/server/03-configure-start.sh deploy/server/04-verify.sh; do
  [ -f "/opt/ut2004/$f" ] && ok "$f uploaded" || bad "$f missing in /opt/ut2004"
done

[ "$fail" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit "$fail"
