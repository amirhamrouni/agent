#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-_project}"
UPSTREAM_COMMIT="ddd5fc34a445bcded3cf9836607aaeebc19a5c78"
EXPECTED_GIT_BLOB="b3fd79533fdb9fcedd077744f7e120920eb6cc97"
REL="assets/external/quaternius_character/character.glb"
DEST="${ROOT}/${REL}"
URL="https://raw.githubusercontent.com/programasweights/avatar/${UPSTREAM_COMMIT}/public/assets/character.glb"

mkdir -p "$(dirname "$DEST")"

curl --fail --silent --show-error --location \
  --retry 4 --retry-delay 2 --retry-all-errors \
  "$URL" -o "$DEST"

ACTUAL_GIT_BLOB="$(git hash-object "$DEST")"
if [[ "$ACTUAL_GIT_BLOB" != "$EXPECTED_GIT_BLOB" ]]; then
  echo "VISUAL_ASSET_HASH_MISMATCH expected=${EXPECTED_GIT_BLOB} actual=${ACTUAL_GIT_BLOB}" >&2
  rm -f "$DEST"
  exit 1
fi

SIZE="$(wc -c < "$DEST" | tr -d ' ')"
if [[ "$SIZE" -lt 500000 ]]; then
  echo "VISUAL_ASSET_SIZE_INVALID bytes=${SIZE}" >&2
  rm -f "$DEST"
  exit 1
fi

echo "VISUAL_ASSET_READY path=${REL} git_blob=${ACTUAL_GIT_BLOB} bytes=${SIZE} upstream=${UPSTREAM_COMMIT}"
