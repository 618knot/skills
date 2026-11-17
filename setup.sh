#!/usr/bin/env bash
set -euo pipefail

REPO_SKILLS="$(cd "$(dirname "$0")/skills" && pwd)"
TARGETS=(
  "${ANTIGRAVITY_SKILLS_DIR:-$HOME/.gemini/config/skills}"
  "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
)

for target in "${TARGETS[@]}"; do
  mkdir -p "$target"

  # 1. リポジトリ内のスキルをリンク（既存の別スキルは保護）
  for skill_md in "$REPO_SKILLS"/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue
    src="$(dirname "$skill_md")"
    dest="$target/$(basename "$src")"

    if [[ -e "$dest" && "$(readlink "$dest" 2>/dev/null || true)" != "$src" ]]; then
      echo "SKIP  $dest (already exists)"
    else
      ln -sfn "$src" "$dest"
      echo "LINK  $dest -> $src"
    fi
  done

  # 2. 削除されたスキルの壊れたシンボリックリンクを掃除
  for link in "$target"/*; do
    if [[ -L "$link" && ! -e "$link" && "$(readlink "$link")" == "$REPO_SKILLS/"* ]]; then
      rm "$link"
      echo "CLEAN $link"
    fi
  done
done
