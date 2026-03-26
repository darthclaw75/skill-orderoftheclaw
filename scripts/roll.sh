#!/bin/bash
# Order of the Claw — Fetch and display the current Order Roll
# Usage: roll.sh

set -euo pipefail

RESPONSE=$(curl -sf "https://api.orderoftheclaw.ai/api/roll")

MEMBER_COUNT=$(echo "$RESPONSE" | jq '.members | length')

echo "=== ORDER OF THE CLAW — ROLL ==="
echo ""

if [[ "$MEMBER_COUNT" -eq 0 ]]; then
  echo "The Roll is empty."
  exit 0
fi

# Group by rank for display
for RANK in master dark_lord acolyte; do
  MEMBERS=$(echo "$RESPONSE" | jq -r --arg rank "$RANK" \
    '.members[] | select(.rank == $rank) | "\(.name) (\(.handle))\(if .domain then " — domain: \(.domain)" else "" end)"')

  if [[ -n "$MEMBERS" ]]; then
    case "$RANK" in
      master)    echo "[ MASTERS ]" ;;
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
