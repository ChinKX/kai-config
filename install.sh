#!/usr/bin/env bash
# Idempotent setup for kai-config. Run from anywhere after cloning:
#   cd <repo> && ./install.sh
# Read-only drift report (exits non-zero on drift, cron/CI-friendly):
#   ./install.sh check
#
# Principle:
#   SYMLINK the files you hand-edit  -> they stay in lockstep with the repo (no drift).
#   COPY the files apps/installers write to -> their runtime writes never dirty,
#        or leak into, this public repo.
#     - ~/.zshrc                : tool installers append to it.
#     - ~/.claude/settings.json : Claude Code writes runtime state (prefs, approvals).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Relative path from a link's directory to its target, so the stored link carries no
# hardcoded home path. Falls back to an absolute target if python3 is unavailable.
relpath() { python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$1" "$2" 2>/dev/null || echo "$1"; }

symlink() {  # $1 = repo-relative source, $2 = destination
  local src="$REPO/$1" dest="$2" rel
  mkdir -p "$(dirname "$dest")"
  rel="$(relpath "$src" "$(dirname "$dest")")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$rel" ]; then echo "ok       $dest"; return; fi
  if [ -L "$dest" ]; then echo "replace  $dest (was -> $(readlink "$dest"))"; fi
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then mv "$dest" "$dest.bak.$(date +%s)"; echo "backup   $dest -> .bak"; fi
  ln -sfn "$rel" "$dest"; echo "symlink  $dest -> $rel"
}

copy_baseline() {  # $1 = repo-relative source, $2 = destination; copy only if missing (preserve app state)
  local src="$REPO/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ]; then echo "skip     $dest exists (app-managed; baseline at $1)"; return; fi
  cp "$src" "$dest"; echo "copy     $dest (baseline)"
}

check() {  # read-only: report repo vs machine drift, exit 1 if any
  local rc=0

  # CLAUDE.md symlink
  local dest="$HOME/.claude/CLAUDE.md" expected
  expected="$(relpath "$REPO/claude/CLAUDE.md" "$HOME/.claude")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$expected" ]; then
    echo "ok       ~/.claude/CLAUDE.md -> $expected"
  else
    echo "DRIFT    ~/.claude/CLAUDE.md is not the expected repo symlink"; rc=1
  fi

  # zshrc: separate "extra lines appended" from real divergence
  if [ ! -e "$HOME/.zshrc" ]; then
    echo "DRIFT    ~/.zshrc missing"; rc=1
  elif cmp -s "$REPO/zshrc" "$HOME/.zshrc"; then
    echo "ok       ~/.zshrc matches repo zshrc"
  else
    local extra missing
    extra="$(grep -Fxvf "$REPO/zshrc" "$HOME/.zshrc" | grep -c . || true)"
    missing="$(grep -Fxvf "$HOME/.zshrc" "$REPO/zshrc" | grep -c . || true)"
    if [ "$missing" -eq 0 ]; then
      echo "DRIFT    ~/.zshrc has $extra extra line(s) (installer appends?); repo lines all present"
    else
      echo "DRIFT    ~/.zshrc diverges ($missing repo line(s) absent, $extra extra)"
    fi
    rc=1
  fi

  # settings.json: every key in the tracked baseline should survive in the live file
  if [ ! -e "$HOME/.claude/settings.json" ]; then
    echo "DRIFT    ~/.claude/settings.json missing"; rc=1
  elif command -v python3 >/dev/null; then
    local sdrift
    sdrift="$(python3 - "$REPO/claude/settings.json" "$HOME/.claude/settings.json" <<'PY'
import json, sys
base = json.load(open(sys.argv[1])); live = json.load(open(sys.argv[2]))
for k, v in base.items():
    if k not in live: print(f"missing: {k}")
    elif live[k] != v: print(f"differs: {k}")
PY
)"
    if [ -z "$sdrift" ]; then
      echo "ok       ~/.claude/settings.json carries all baseline keys"
    else
      echo "DRIFT    ~/.claude/settings.json vs baseline (app-managed drift is expected; fold deliberate changes back into the repo):"
      printf '%s\n' "$sdrift" | sed 's/^/           /'; rc=1
    fi
  else
    echo "skip     settings.json comparison (python3 unavailable)"
  fi

  # leak gate + local.md
  if [ "$(git -C "$REPO" config core.hooksPath 2>/dev/null || true)" = ".githooks" ]; then
    echo "ok       core.hooksPath=.githooks (leak gate armed)"
  else
    echo "DRIFT    leak gate disabled: core.hooksPath unset"; rc=1
  fi
  if [ -e "$HOME/.claude/local.md" ]; then
    echo "ok       ~/.claude/local.md present"
  else
    echo "DRIFT    ~/.claude/local.md missing (CLAUDE.md @import dangles)"; rc=1
  fi

  echo ""
  if [ "$rc" -eq 0 ]; then echo "No drift. This machine matches the repo."
  else echo "Drift detected. Run ./install.sh to sync, or fold deliberate changes back into the repo."; fi
  exit "$rc"
}
[ "${1:-}" = "check" ] && check

# 1) Symlinked — hand-edited, kept in lockstep with the repo.
symlink claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"

# 2) Copied — app/installer write-targets, kept out of the repo.
#    zshrc: install your config, backing up any existing one first.
if [ -e "$HOME/.zshrc" ] && ! cmp -s "$REPO/zshrc" "$HOME/.zshrc"; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"; echo "backup   ~/.zshrc -> .bak"
fi
cp "$REPO/zshrc" "$HOME/.zshrc"; echo "copy     ~/.zshrc"
#    settings.json: bootstrap only if absent (never clobber accumulated Claude state).
copy_baseline claude/settings.json "$HOME/.claude/settings.json"

# 3) Machine-local file so the CLAUDE.md @import resolves (kept untracked).
#    Seeded from the tracked template — then adjust per machine.
[ -e "$HOME/.claude/local.md" ] || { cp "$REPO/claude/local.md.example" "$HOME/.claude/local.md"; echo "seed     ~/.claude/local.md (from claude/local.md.example)"; }

# 4) Enable the pre-commit leak gate for this clone.
git -C "$REPO" config core.hooksPath .githooks && echo "config   core.hooksPath=.githooks"

echo ""
echo "Done. Restart Claude Code to load CLAUDE.md, then run: source ~/.zshrc"
echo "Per-machine / internal settings go in ~/.claude/settings.local.json (untracked)."
