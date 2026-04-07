#!/usr/bin/env bash
# Verifica se os 24 PNG listados em expected-png-manifest.txt existem em reference/png/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PNG_DIR="${ROOT_DIR}/reference/png"
MANIFEST="${SCRIPT_DIR}/expected-png-manifest.txt"

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifest não encontrado: $MANIFEST" >&2
  exit 2
fi

mapfile -t NAMES < <(grep -v '^[[:space:]]*$' "$MANIFEST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
EXPECTED=${#NAMES[@]}
if [[ "$EXPECTED" -ne 24 ]]; then
  echo "O manifest deve listar exatamente 24 ficheiros; encontrados: $EXPECTED ($MANIFEST)" >&2
  exit 2
fi
MISSING=()

for name in "${NAMES[@]}"; do
  if [[ ! -f "${PNG_DIR}/${name}" ]]; then
    MISSING+=("$name")
  fi
done

echo "Pasta: $PNG_DIR"
echo "Manifest: $MANIFEST (${EXPECTED} ficheiros esperados)"
echo ""

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo "OK: todos os ${EXPECTED} PNG estão presentes."
  exit 0
fi

echo "FALTAM ${#MISSING[@]} ficheiro(s):"
for m in "${MISSING[@]}"; do
  echo "  - $m"
done
echo ""
echo "Presentes: $((EXPECTED - ${#MISSING[@]})) / ${EXPECTED}"
exit 1
