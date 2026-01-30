#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/new-post.sh "포스트 제목" [category]
# Example:
#   ./scripts/new-post.sh "Jekyll 빌드 에러 해결" ops

TITLE_RAW="${1:-}"
CATEGORY="${2:-notes}"

if [[ -z "$TITLE_RAW" ]]; then
  echo "Usage: $0 \"Post title\" [category]" >&2
  exit 1
fi

# Date/time in Asia/Seoul (+0900)
DATE_YMD=$(TZ=Asia/Seoul date +%F)
DATE_FULL=$(TZ=Asia/Seoul date '+%Y-%m-%d %H:%M:%S %z')
TIME_HM=$(TZ=Asia/Seoul date +%H%M)

# slugify (simple ASCII slug)
SLUG=$(echo "$TITLE_RAW" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[[:space:]]+/-/g' \
  | sed -E 's/[^a-z0-9-]+//g' \
  | sed -E 's/-+/-/g' \
  | sed -E 's/^-|-$//g')

# If the title is non-ASCII (e.g. Korean), slugify becomes empty.
# Use a time-based fallback to avoid collisions within the same day.
if [[ -z "$SLUG" ]]; then
  SLUG="post-${TIME_HM}"
fi

POST_DIR="_posts"
FILE="$POST_DIR/${DATE_YMD}-${SLUG}.md"
TEMPLATE="templates/post.md"

if [[ -f "$FILE" ]]; then
  echo "Already exists: $FILE" >&2
  exit 1
fi

mkdir -p "$POST_DIR"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Missing template: $TEMPLATE" >&2
  exit 1
fi

# Escape quotes for YAML title
TITLE_YAML=${TITLE_RAW//"/\\"}

sed \
  -e "s/{{TITLE}}/${TITLE_YAML}/g" \
  -e "s/{{DATE}}/${DATE_FULL}/g" \
  -e "s/{{CATEGORY}}/${CATEGORY}/g" \
  "$TEMPLATE" > "$FILE"

echo "Created: $FILE"

# Open in editor if available
if command -v code >/dev/null 2>&1; then
  code "$FILE" >/dev/null 2>&1 || true
fi
