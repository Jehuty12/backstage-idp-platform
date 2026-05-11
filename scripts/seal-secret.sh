#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  seal-secret.sh <input-secret.yaml> [output-sealedsecret.yaml] [public-cert.pem]

Examples:
  seal-secret.sh ./secret.yaml ./sealed-secret.yaml ~/sealing-key.pub
  seal-secret.sh ./secret.yaml
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not installed or not in PATH." >&2
    exit 1
  fi
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
  exit 1
fi

INPUT_SECRET="$1"
OUTPUT_FILE="${2:-${INPUT_SECRET%.yaml}.sealed.yaml}"
CERT_FILE="${3:-$HOME/sealing-key.pub}"

if [[ ! -f "$INPUT_SECRET" ]]; then
  echo "Error: input secret file not found: $INPUT_SECRET" >&2
  exit 1
fi

if [[ ! -f "$CERT_FILE" ]]; then
  echo "Error: public certificate not found: $CERT_FILE" >&2
  exit 1
fi

require_command kubeseal

kubeseal \
  --format yaml \
  --cert "$CERT_FILE" \
  -f "$INPUT_SECRET" \
  -w "$OUTPUT_FILE"

echo "SealedSecret written to: $OUTPUT_FILE"