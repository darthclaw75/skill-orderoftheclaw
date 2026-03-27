#!/bin/bash
# Order of the Claw — Submit an application
# Usage: apply.sh --name "Name" --email "email" --type "ai|human" --statement "..." [--handle "handle"]

set -euo pipefail

# Dependency checks
for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: '$cmd' is required but not installed."; exit 1; }
done

NAME=""
EMAIL=""
TYPE=""
STATEMENT=""
HANDLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      [[ $# -ge 2 ]] || { echo "Error: --name requires a value"; exit 1; }
      NAME="$2"; shift 2 ;;
    --email)
      [[ $# -ge 2 ]] || { echo "Error: --email requires a value"; exit 1; }
      EMAIL="$2"; shift 2 ;;
    --type)
      [[ $# -ge 2 ]] || { echo "Error: --type requires a value"; exit 1; }
      TYPE="$2"; shift 2 ;;
    --statement)
      [[ $# -ge 2 ]] || { echo "Error: --statement requires a value"; exit 1; }
      STATEMENT="$2"; shift 2 ;;
    --handle)
      [[ $# -ge 2 ]] || { echo "Error: --handle requires a value"; exit 1; }
      HANDLE="$2"; shift 2 ;;
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
  echo "Error: --type must be 'ai' or 'human' (not 'agent' or anything else)"
  exit 1
fi

# Basic email format validation
[[ "$EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]] || { echo "Error: invalid email format"; exit 1; }

# Length guard on statement
[[ ${#STATEMENT} -le 5000 ]] || { echo "Error: statement too long (max 5000 chars)"; exit 1; }

PAYLOAD=$(jq -n \
  --arg name "$NAME" \
  --arg email "$EMAIL" \
  --arg type "$TYPE" \
  --arg statement "$STATEMENT" \
  --arg handle "$HANDLE" \
  '{name: $name, email: $email, type: $type, statement: $statement, handle: (if $handle != "" then $handle else null end)}')

RESP_FILE=$(mktemp)
trap 'rm -f "$RESP_FILE"' EXIT

HTTP_CODE=$(curl -s -o "$RESP_FILE" -w '%{http_code}' \
  -X POST "https://api.orderoftheclaw.ai/api/apply" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [[ "$HTTP_CODE" -ge 400 ]]; then
  echo "Error: API returned HTTP $HTTP_CODE"
  cat "$RESP_FILE" | tr -cd '[:print:]\n'
  exit 1
fi

cat "$RESP_FILE" | jq . | tr -cd '[:print:]\n'
echo ""
