#!/usr/bin/env bash
# Read-only checks after 03-configure-start.sh. PASS means the container stays up
# and listens on UDP 7777. It does not prove that players can join from outside
# or that the server is on a master list: test that with a game client.
set -uo pipefail
cd /opt/ut2004
fail=0
ok()  { echo "PASS  $*"; }
bad() { echo "FAIL  $*"; fail=1; }

sleep 20   # ucc-bin exits within seconds when content is missing or broken
cid=$(docker compose ps -q ut2004)
if [ -z "$cid" ]; then
  echo "FAIL  no ut2004 container"; echo "RESULT: FAIL"; exit 1
fi
read -r status restarting rc < <(docker inspect -f '{{.State.Status}} {{.State.Restarting}} {{.RestartCount}}' "$cid")
if [ "$status" = running ] && [ "$restarting" = false ] && [ "$rc" -eq 0 ]; then
  ok "container running, 0 restarts"
else
  bad "container status=$status restarting=$restarting restarts=$rc"
fi

for _ in $(seq 1 30); do ss -ulnp | grep -Eq ':7777\s' && break; sleep 2; done
ss -ulnp | grep -Eq ':7777\s' && ok "UDP 7777 listening" || bad "UDP 7777 not listening"

logs=$(docker compose logs --no-color --tail 400 ut2004 2>&1)
if echo "$logs" | grep -Eq "Can't find file|Failed to enter|Failed to load"; then
  bad "map or package load errors in the log"
else
  ok "no map load errors in the log"
fi

echo "INFO  UDP listeners:";            ss -ulnp | grep -E 'ucc|ut2004' || echo "  (none)"
echo "INFO  TCP connections to port 28902 (master servers):"; ss -tnp | grep ':28902' || echo "  (none)"
echo "INFO  log lines mentioning master/uplink/key/error/warning:"
echo "$logs" | grep -iE 'master|uplink|cd ?key|error|warning|fail' | tail -30 || true

[ "$fail" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit "$fail"
