# kai-config — personal setup tracking repo

> **Status: SUPERSEDED (2026-06)** — kept for history. This documents the original v1 (pure backup repo: manual `cp` in both directions, **no symlinks**, `settings.json` out of scope). The shipped design has since moved on — `CLAUDE.md` is a relative symlink, `settings.json` is a copied baseline, setup runs via `install.sh`, and a pre-commit leak gate guards the repo. See [README.md](../../../README.md) for the current approach.

## Overview

A single git repo at `~/Desktop/dev/kai-config` that tracks two personal config files (`~/.zshrc` and `~/.claude/CLAUDE.md`) for backup, cross-machine sync, and public showcase. v1 MVP is a pure backup repo: plain copies of the stripped files, committed to git. No symlinks, no install scripts, no sync tool — manual copy in both directions. This keeps the surface area to "git + cp" and leaves room to upgrade to symlinks, GNU Stow, or chezmoi later without breaking anything.

## Goals

- Version history for personal config files.
- A clean, public-shareable snapshot of the config (no secrets, no hardcoded user paths).
- A new machine can restore the config with `cp` commands documented in the README.

## Non-goals (v1)

- Automated sync (chezmoi, stow, symlinks, install scripts).
- `~/.claude/settings.json` (too many third-party hooks and hardcoded paths).
- `~/.claude/agents/`, `~/.claude/skills/` (custom files).
- VS Code extensions, settings, keybindings.
- `~/.claude/hooks/` scripts.
- Bun, opencode, and RTK shell/config lines — treated as external tool deps; reinstall the tool on a new machine and it adds its own lines back.

## Repo layout

```
~/Desktop/dev/kai-config/
├── .git/
├── .gitignore
├── README.md
├── docs/
│   └── superpowers/
│       ├── specs/
│       │   └── 2026-05-11-kai-config-design.md   (this file)
│       └── plans/
│           └── 2026-05-11-kai-config-setup.md
├── zshrc                                         → manual copy of stripped ~/.zshrc
└── claude/
    └── CLAUDE.md                                 → manual copy of cleaned ~/.claude/CLAUDE.md
```

Tracked filenames have no dot prefix (e.g. `zshrc` not `.zshrc`) — keeps them visible in `ls`, prevents shells/tools from accidentally sourcing them from the repo, and makes the manual cp commands explicit about the destination.

## File details

### `zshrc` (→ `~/.zshrc`)

Source-of-truth is the current `~/.zshrc` with these blocks removed before committing:

- The `opencode` PATH export block (one `export PATH=/Users/<user>/.opencode/bin:$PATH` line plus its `# opencode` comment).
- The `# bun completions` block (the `[ -s "/Users/<user>/.bun/_bun" ] && source ...` line).
- The `# bun` block (the `BUN_INSTALL` and `PATH` exports).

Rationale: each references a tool installed outside this repo's scope. The opencode and bun-completions lines reference hardcoded user paths that break on other machines. The remaining bun env block uses `$HOME` and is portable, but it's removed too because the user wants bun treated uniformly as an external dep — reinstall bun on a new machine and its installer re-adds all three blocks.

After stripping, the tracked `zshrc` contains no hardcoded user paths and no machine-specific values.

### `claude/CLAUDE.md` (→ `~/.claude/CLAUDE.md`)

Source-of-truth is the current `CLAUDE.md` with the trailing `@RTK.md` line removed. RTK is an external tool installed separately; its reference doc isn't part of this repo, and the `@` include would fail at load time on any machine that hasn't separately installed RTK.

### `.gitignore`

```
.DS_Store
```

### `README.md`

Documents:
- What the repo is and who it's for (one paragraph).
- External tool prerequisites with install links (RTK, bun, opencode).
- Fresh-machine restore: explicit `cp` commands for each tracked file.
- Day-to-day source-machine sync: explicit `cp` commands for each tracked file, with a reminder to re-strip the bun/opencode/@RTK.md lines.

## Workflows

### Source-machine sync (live → repo)

After editing `~/.zshrc` or `~/.claude/CLAUDE.md` directly:

1. `cp ~/.zshrc ~/Desktop/dev/kai-config/zshrc`
2. Open `zshrc` in editor and re-strip the bun + opencode blocks (or use a sed one-liner documented in README).
3. `cp ~/.claude/CLAUDE.md ~/Desktop/dev/kai-config/claude/CLAUDE.md`
4. Open `claude/CLAUDE.md` in editor and remove the trailing `@RTK.md` line.
5. `git diff` to verify only intended changes.
6. `git commit -am "..."` and `git push`.

### Fresh-machine restore (repo → live)

1. `git clone <repo> ~/Desktop/dev/kai-config`
2. `cp ~/Desktop/dev/kai-config/zshrc ~/.zshrc`
3. `mkdir -p ~/.claude && cp ~/Desktop/dev/kai-config/claude/CLAUDE.md ~/.claude/CLAUDE.md`
4. Install external tool deps you want: RTK, bun, opencode (the installers re-add their shell lines).
5. `source ~/.zshrc`.
6. Restart Claude Code to load CLAUDE.md.

## Validation

- After committing, `git diff HEAD~1 -- zshrc claude/CLAUDE.md` shows only the intentional strips.
- `grep -E "bun|opencode|@RTK" zshrc claude/CLAUDE.md` returns no matches.
- No hardcoded `/Users/<your-username>` paths in tracked files: `grep -r /Users/ . --exclude-dir=.git --exclude-dir=docs` returns nothing.

## Future (not v1)

- Add symlink-based sync (`install.sh` or GNU Stow) when the manual cp dance gets annoying.
- Re-evaluate chezmoi once secrets/templating become real needs.
- Track `~/.claude/settings.json` with whatever sync mechanism we adopt (will need path templating).
- Track custom Claude artefacts: `~/.claude/agents/coden-ramsay.md`, `~/.claude/skills/ast-grep/`.
- Track VS Code: extensions list, user settings, keybindings.
- Track custom `~/.claude/hooks/` scripts (e.g. `rtk-rewrite.sh`).
