#!/usr/bin/env bash
set -euo pipefail
NAME="${1:?usage: addmodel <name> <hf_repo> <file_in_repo> <comfyui_subfolder>}"
REPO="${2:?missing hf_repo}"
FILE="${3:?missing file_in_repo}"
SUB="${4:?missing comfyui_subfolder}"
: "${R2_BUCKET:?set R2_BUCKET}"
BASE="$(basename "$FILE")"
DEST="r2:${R2_BUCKET}/comfy-models/${NAME}/${SUB}/${BASE}"
if rclone lsf "$DEST" >/dev/null 2>&1; then echo ">>> already in R2: ${NAME}/${SUB}/${BASE}"; exit 0; fi
echo ">>> downloading ${BASE} from ${REPO} ..."
hf download "$REPO" "$FILE" --local-dir /tmp/addmodel >/dev/null
echo ">>> uploading to ${DEST} ..."
rclone copyto "/tmp/addmodel/${FILE}" "$DEST" --transfers 8 --progress
rm -f "/tmp/addmodel/${FILE}"
echo ">>> done. On any pod:  getmodel ${NAME}"
