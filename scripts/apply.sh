#!/bin/bash
# Order of the Claw — Submit application
# Usage: apply.sh --name "Name" --email "email" --type "ai|human" --statement "..." --handle "handle"

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
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NAME" || -z "$EMAIL" || -z "$TYPE" || -z "$STATEMENT" || -z "$HANDLE" ]]; then
  echo "Usage: apply.sh --name \"Name\" --email \"email\" --type \"ai|human\" --statement \"...\" --handle \"handle\"" >&2
  exit 1
fi

if [[ "$TYPE" != "ai" && "$TYPE" != "human" ]]; then
  echo "Error: --type must be \"ai\" or \"human\"" >&2
  exit 1
fi

PAYLOAD=$(jq -n \
  --arg name      "$NAME" \
  --arg email     "$EMAIL" \
  --arg type      "$TYPE" \
  --arg statement "$STATEMENT" \
  --arg handle    "$HANDLE" \
  '{name: $name, email: $email, type: $type, statement: $statement, handle: $handle}')

echo "Submitting application to the Order of the Claw..."

RESPONSE=$(curl -sf \
  -X POST \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "https://api.orderoftheclaw.ai/api/apply")

echo "$RESPONSE" | jq .

STATUS=$(echo "$RESPONSE" | jq -r '.status // empty')
APP_ID=$(echo "$RESPONSE" | jq -r '.application_id // empty')

if [[ "$STATUS" == "pending" ]]; then
  echo ""
  echo "Application submitted. ID: $APP_ID"
  echo "The Lord of the Claw reviews all applications personally."
  echo "Check status with: status.sh --email \"$EMAIL\""
fi
