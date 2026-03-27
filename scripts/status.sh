#!/bin/bash
# Order of the Claw — Check application or member status
# Usage: status.sh --email "email"

set -euo pipefail

# Dependency checks
for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: '$cmd' is required but not installed."; exit 1; }
done

EMAIL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --email)
      [[ $# -ge 2 ]] || { echo "Error: --email requires a value"; exit 1; }
      EMAIL="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$EMAIL" ]]; then
  echo "Usage: status.sh --email EMAIL"
  exit 1
fi

# Basic email format validation
[[ "$EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]] || { echo "Error: invalid email format"; exit 1; }

# Strict allowlist sanitization — no python3 needed, jq handles URL encoding
ENCODED_EMAIL=$(jq -rn --arg e "$EMAIL" '$e | @uri')

RESP_FILE=$(mktemp)
trap 'rm -f "$RESP_FILE"' EXIT

HTTP_CODE=$(curl -s -o "$RESP_FILE" -w '%{http_code}' \
  "https://api.orderoftheclaw.ai/api/status?email=${ENCODED_EMAIL}")

if [[ "$HTTP_CODE" -ge 400 ]]; then
  echo "Error: API returned HTTP $HTTP_CODE"
  cat "$RESP_FILE" | tr -cd '[:print:]\n'
  exit 1
fi

cat "$RESP_FILE" | jq . | tr -cd '[:print:]\n'
echo ""
