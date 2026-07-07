#!/usr/bin/env bash
# Idempotent setup for kai-config. Run from anywhere after cloning:
#   cd <repo> && ./install.sh
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

# 1) Symlinked — hand-edited, kept in lockstep with the repo.
symlink claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"

# 2) Copied — app/installer write-targets, kept out of the repo.
#    zshrc: install your config, backing up any existing one first. Lines that
#    tool installers appended (bun, opencode, ...) are migrated to the untracked
#    ~/.zshrc.local, which the managed zshrc sources — so re-installs never
#    deactivate them.
if [ -e "$HOME/.zshrc" ] && ! cmp -s "$REPO/zshrc" "$HOME/.zshrc"; then
  extra="$(grep -Fxvf "$REPO/zshrc" "$HOME/.zshrc" || true)"
  if [ -n "$extra" ]; then
    if [ -e "$HOME/.zshrc.local" ] && grep -Fxq "$(printf '%s' "$extra" | head -n1)" "$HOME/.zshrc.local"; then
      echo "skip     ~/.zshrc.local already has the extra lines"
    else
      { echo ""; echo "# migrated from ~/.zshrc by install.sh on $(date +%F)"; printf '%s\n' "$extra"; } >> "$HOME/.zshrc.local"
      echo "migrate  ~/.zshrc extra lines -> ~/.zshrc.local"
    fi
  fi
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

# 5) Warn about optional tools zshrc guards for, so shells stay clean but you know what's missing.
missing=()
command -v cargo  >/dev/null 2>&1 || missing+=("cargo (rustup):  https://rustup.rs")
command -v fzf    >/dev/null 2>&1 || missing+=("fzf:              brew install fzf")
command -v zoxide >/dev/null 2>&1 || missing+=("zoxide:           brew install zoxide")
command -v nvim   >/dev/null 2>&1 || missing+=("nvim:             brew install neovim")
if [ "${#missing[@]}" -gt 0 ]; then
  echo ""
  echo "warn     zshrc guards these but they're not installed yet:"
  for m in "${missing[@]}"; do echo "           $m"; done
fi

echo ""
echo "Done. Restart Claude Code to load CLAUDE.md, then run: source ~/.zshrc"
echo "Per-machine / internal settings go directly in ~/.claude/settings.json (a local copy, never tracked)."
