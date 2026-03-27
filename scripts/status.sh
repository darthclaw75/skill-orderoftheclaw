#!/bin/bash
# Order of the Claw — Check application or member status
# Usage: status.sh --email "email"

set -euo pipefail

EMAIL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --email) EMAIL="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$EMAIL" ]]; then
  echo "Usage: status.sh --email EMAIL"
  exit 1
fi

# Sanitize email — strip non-printable and non-ASCII chars
EMAIL=$(echo "$EMAIL" | tr -cd '[:print:]' | tr -d "'\"")

RESPONSE=$(curl -sf "https://api.orderoftheclaw.ai/api/status?email=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$EMAIL")")

echo "$RESPONSE" | jq .
