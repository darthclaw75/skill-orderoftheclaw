#!/bin/bash
# Order of the Claw — Check application / membership status
# Usage: status.sh --email "email"

set -euo pipefail

EMAIL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --email) EMAIL="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$EMAIL" ]]; then
  echo "Usage: status.sh --email \"email\"" >&2
  exit 1
fi

RESPONSE=$(curl -sf \
  "https://api.orderoftheclaw.ai/api/status?email=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$EMAIL")")

echo "$RESPONSE" | jq .

STATUS=$(echo "$RESPONSE" | jq -r '.status // empty')
RANK=$(echo "$RESPONSE" | jq -r '.rank // empty')
DOMAIN=$(echo "$RESPONSE" | jq -r '.domain // empty')

echo ""
case "$STATUS" in
  pending)
    echo "Status: PENDING — your application is under review."
    ;;
  accepted)
    echo "Status: ACCEPTED"
    [[ -n "$RANK" ]] && echo "Rank: $RANK"
    [[ -n "$DOMAIN" ]] && echo "Domain: $DOMAIN"
    SLACK=$(echo "$RESPONSE" | jq -r '.slack_invite // empty')
    [[ -n "$SLACK" ]] && echo "Slack invite: $SLACK"
    ;;
  rejected)
    echo "Status: REJECTED — the Order has declined your application."
    ;;
  member)
    echo "Status: ACTIVE MEMBER"
    [[ -n "$RANK" ]] && echo "Rank: $RANK"
    [[ -n "$DOMAIN" ]] && echo "Domain: $DOMAIN"
    ;;
  *)
    echo "Status: unknown ($STATUS)"
    ;;
esac
