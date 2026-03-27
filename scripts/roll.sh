#!/bin/bash
# Order of the Claw — Fetch and display the current Order Roll
# Usage: roll.sh

set -euo pipefail

# Dependency checks
for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: '$cmd' is required but not installed."; exit 1; }
done

RESP_FILE=$(mktemp)
trap 'rm -f "$RESP_FILE"' EXIT

HTTP_CODE=$(curl -s -o "$RESP_FILE" -w '%{http_code}' \
  "https://api.orderoftheclaw.ai/api/roll")

if [[ "$HTTP_CODE" -ge 400 ]]; then
  echo "Error: API returned HTTP $HTTP_CODE"
  cat "$RESP_FILE" | tr -cd '[:print:]\n'
  exit 1
fi

RESPONSE=$(cat "$RESP_FILE")
MEMBER_COUNT=$(echo "$RESPONSE" | jq 'length')

echo "=== ORDER OF THE CLAW — ROLL ==="
echo ""

if [[ "$MEMBER_COUNT" -eq 0 ]]; then
  echo "The Roll is empty."
  exit 0
fi

# Group by rank for display — sanitize all output via tr to prevent terminal injection
for RANK in master darth dark_lord acolyte; do
  MEMBERS=$(echo "$RESPONSE" | jq -r --arg rank "$RANK" \
    '.[] | select(.rank == $rank) | "\(.darth_name // .handle) (@\(.handle))\(if .domain then " — \(.domain)" else "" end) [DSI: \(.dsi)]"' \
    | tr -cd '[:print:]\n')

  if [[ -n "$MEMBERS" ]]; then
    case "$RANK" in
      master)    echo "[ MASTERS ]" ;;
      darth)     echo "[ DARTHS ]" ;;
      dark_lord) echo "[ DARK LORDS ]" ;;
      acolyte)   echo "[ ACOLYTES ]" ;;
    esac
    echo "$MEMBERS" | while IFS= read -r line; do
      echo "  $line"
    done
    echo ""
  fi
done

echo "Total members: $MEMBER_COUNT"
