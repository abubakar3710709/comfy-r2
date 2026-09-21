#!/usr/bin/env bash
set -uo pipefail
: "${R2_BUCKET:?set R2_BUCKET}"
DEST=/app/ComfyUI/models
if [ "${1:-}" = "--list" ] || [ -z "${1:-}" ]; then
  echo "Bundles in r2:${R2_BUCKET}/comfy-models :"
  rclone lsf --dirs-only "r2:${R2_BUCKET}/comfy-models" 2>/dev/null | sed 's#/$##;s/^/  - /' \
    || echo "  (none yet)"
  [ -z "${1:-}" ] && { echo; echo "Usage: getmodel <name>"; exit 0; }
  exit 0
fi
for NAME in "$@"; do
  SRC="r2:${R2_BUCKET}/comfy-models/${NAME}"
  rclone lsf "$SRC" >/dev/null 2>&1 || { echo "!! no bundle '${NAME}' — try: getmodel --list"; continue; }
  echo ">>> loading '${NAME}' ..."
  rclone copy "$SRC" "$DEST" --transfers 8 --checkers 16 --fast-list --progress
  echo ">>> '${NAME}' ready."
done
echo ">>> reload the ComfyUI page and pick the model in the loader nodes."
