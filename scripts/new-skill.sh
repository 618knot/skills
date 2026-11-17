#!/usr/bin/env bash
set -euo pipefail

NAME="${1:?Usage: $0 <skill-name> [description]}"
DESC="${2:-Use this skill when ...}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/skills/$NAME"

if [[ -e "$DEST" ]]; then
  echo "Error: $DEST already exists" >&2
  exit 1
fi

mkdir -p "$DEST"
sed -e "s|__SKILL_NAME__|$NAME|g" -e "s|__SKILL_DESCRIPTION__|$DESC|g" \
  "$ROOT/templates/skill-template/SKILL.md" > "$DEST/SKILL.md"

echo "Created: $DEST/SKILL.md"
