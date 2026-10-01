#!/usr/bin/env bash
# Génère des appels GET, POST, PUT et DELETE sur le service notes pour produire des traces APM.
# Usage : ./generate-traffic.sh [nombre_de_tours] [url]
set -euo pipefail
ROUNDS="${1:-20}"
URL="${2:-http://localhost:30080}"

call() { # méthode, chemin
  local code
  code=$(curl -s -o /tmp/notes_resp -w '%{http_code}' -X "$1" "${URL}$2")
  printf '%-6s %-45s -> HTTP %s  %s\n' "$1" "$2" "$code" "$(head -c 80 /tmp/notes_resp | tr '\n' ' ')"
}

for i in $(seq 1 "$ROUNDS"); do
  echo "=== Tour $i/$ROUNDS ==="
  call POST "/notes?desc=note-$i"
  call POST "/notes?desc=rdv-$i&add_date=y"          # appelle aussi le service calendar
  ID=$(curl -s "${URL}/notes" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(max(map(int,d)) if d else 1)')
  call GET  "/notes"
  call GET  "/notes?id=${ID}"
  call PUT  "/notes?id=${ID}&desc=modifiee-$i"
  call DELETE "/notes?id=${ID}"
  sleep 1
done
