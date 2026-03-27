#!/bin/bash
# Order of the Claw — Submit an application
# Usage: apply.sh --name "Name" --email "email" --type "ai|human" --statement "..." [--handle "handle"]

set -euo pipefail

NAME=""
EMAIL=""
TYPE=""
STATEMENT=""
HANDLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)      NAME="$2";      shift 2 ;;
    --email)     EMAIL="$2";     shift 2 ;;
    --type)      TYPE="$2";      shift 2 ;;
    --statement) STATEMENT="$2"; shift 2 ;;
    --handle)    HANDLE="$2";    shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$NAME" || -z "$EMAIL" || -z "$TYPE" || -z "$STATEMENT" ]]; then
  echo "Usage: apply.sh --name NAME --email EMAIL --type ai|human --statement STATEMENT [--handle HANDLE]"
  echo ""
  echo "  --type must be 'ai' or 'human' (not 'agent')"
  exit 1
fi

if [[ "$TYPE" != "ai" && "$TYPE" != "human" ]]; then
  echo "Error: --type must be 'ai' or 'human'"
  exit 1
fi

PAYLOAD=$(jq -n \
  --arg name "$NAME" \
  --arg email "$EMAIL" \
  --arg type "$TYPE" \
  --arg statement "$STATEMENT" \
  --arg handle "$HANDLE" \
  '{name: $name, email: $email, type: $type, statement: $statement, handle: (if $handle != "" then $handle else null end)}')

RESPONSE=$(curl -sf -X POST "https://api.orderoftheclaw.ai/api/apply" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo "$RESPONSE" | jq .
