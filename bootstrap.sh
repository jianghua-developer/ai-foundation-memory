#!/usr/bin/env bash
# bootstrap.sh — 重建各系列仓的 CLAUDE.md 符号链接（单源收编）。
#
# 设计：各仓 ~/project/<repo>/CLAUDE.md 是符号链接 → ../ai-foundation-memory/claude/<repo>.md
#   canonical 在私有仓 ai-foundation-memory/claude/，随私有 git 版本化（重装/迁移后 git clone + 本脚本重建）。
# 相对路径 symlink：Claude Code 的 @import 按逻辑路径解析（实证 LOGICAL），
#   canonical 内的 `@../ai-foundation-memory/series-overview.md` 在 repo 根仍解析到真实 series-overview。
#
# 用法：从 ~/project/ai-foundation-memory/ 运行 `./bootstrap.sh`（或任意处传项目根为 $1）。
set -euo pipefail

ROOT="${1:-$HOME/project}"
MEM="$ROOT/ai-foundation-memory"
STORE="$MEM/claude"

# 需要收编的系列仓
REPOS=(
  fullstack-bridge
  python-fastapi-template
  vite-react-spa-template
  vite-vue-spa-template
  frontend-template-copier
  bridge-mcp-server
  ai-foundation-review
  fullstack-param-protocol
)

echo "项目根: $ROOT"
echo "收编点: $STORE"
for repo in "${REPOS[@]}"; do
  src="$STORE/$repo.md"
  dst="$ROOT/$repo/CLAUDE.md"
  if [ ! -f "$src" ]; then
    echo "⚠️  缺 canonical: $src（跳过）"
    continue
  fi
  if [ ! -d "$ROOT/$repo" ]; then
    echo "⚠️  缺目标目录: $ROOT/$repo（跳过）"
    continue
  fi
  # 相对链接（src 相对 dst 所在目录）：~/project 整体迁移后仍存活
  rel="$(python3 -c "import os,sys;print(os.path.relpath('$src', '$ROOT/$repo'))")"
  ln -sfn "$rel" "$dst"
  echo "✓  $repo/CLAUDE.md → $rel"
done

echo
echo "校验链接:"
for repo in "${REPOS[@]}"; do
  printf '  %-26s %s\n' "$repo" "$([ -L "$ROOT/$repo/CLAUDE.md" ] && echo "symlink OK" || echo "非 symlink（需手动检查）")"
done
