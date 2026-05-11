# kai-config — personal setup tracking repo

## Overview

A single git repo at `~/Desktop/dev/kai-config` that tracks two personal config files (`~/.zshrc` and `~/.claude/CLAUDE.md`) for backup, cross-machine sync, and public showcase. Uses `chezmoi` as the sync engine so machine-specific values can be templated cleanly as the repo grows.

## Goals

- Version history for personal config files.
- One-command restore on a fresh machine.
- Public-share-ready: no secrets, no hardcoded paths, no machine-specific values in committed files.

## Non-goals (v1)

The following are deliberately deferred. They can be added in later iterations without restructuring the repo.

- `~/.claude/settings.json` — has too many third-party-plugin hooks and hardcoded paths for v1.
- `~/.claude/agents/` and `~/.claude/skills/` (custom only).
- VS Code extensions list, user `settings.json`, `keybindings.json`.
- `~/.claude/hooks/` scripts.
- Bun, opencode, and RTK shell/config lines — treated as external tool dependencies; their configs are not part of this repo.

## Approach

Chosen: **chezmoi at a custom source location.** The repo stays where it was created (`~/Desktop/dev/kai-config`) instead of moving to chezmoi's default `~/.local/share/chezmoi`. Per-machine config in `~/.config/chezmoi/chezmoi.toml` points chezmoi at the custom location.

Two approaches were considered and rejected:
- **Pure chezmoi convention** (repo at `~/.local/share/chezmoi`) — most idiomatic, zero per-machine config, but the repo is buried out of the visible dev folder.
- **Plain bash install script** — viable now that v1 has zero templating, but locks out future-us from chezmoi's `add`/`edit`/`diff`/`apply` ergonomics and templating once we want to track `settings.json` or encrypted secrets.

Keeping chezmoi pays a tiny upfront cost (one 2-line toml per machine) and avoids a migration when scope expands.

## Repo layout

```
~/Desktop/dev/kai-config/
├── .git/
├── .gitignore
├── .chezmoiignore
├── README.md
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-05-11-kai-config-design.md   (this file)
├── dot_zshrc                                     → ~/.zshrc
└── dot_claude/
    └── CLAUDE.md                                 → ~/.claude/CLAUDE.md
```

chezmoi naming in play:
- `dot_` prefix → destination becomes a dotfile (`dot_zshrc` → `.zshrc`).
- No `.tmpl` suffix in v1 — no templating needed once external-tool lines are stripped.
- No `private_` prefix — neither tracked file is sensitive, and `~/.claude/` already exists with other content chezmoi doesn't manage.

## File details

### `dot_zshrc` → `~/.zshrc`

Source-of-truth is the current `~/.zshrc` with these blocks removed before committing:

- The `opencode` PATH export block (single `export PATH=/Users/<user>/.opencode/bin:$PATH` line).
- The `# bun completions` block (the `[ -s "/Users/<user>/.bun/_bun" ] && source ...` line).
- The `# bun` block (the `BUN_INSTALL` and `PATH` exports).

Rationale: each references a tool installed outside this repo's scope. Their lines either break (hardcoded user paths) or are inert (env vars pointing at non-existent dirs) if the tool isn't installed on a target machine. Users who want bun/opencode reinstall the tool, which re-adds its own lines.

After stripping, the tracked `dot_zshrc` contains no hardcoded user paths and no machine-specific values, so no `.tmpl` suffix is needed.

### `dot_claude/CLAUDE.md` → `~/.claude/CLAUDE.md`

Source-of-truth is the current `CLAUDE.md` with the trailing `@RTK.md` line removed. RTK is an external tool installed separately; its reference doc isn't part of this repo. The `@` include would fail at load time on any machine that hasn't separately installed RTK and placed its `RTK.md` next to `CLAUDE.md`.

### `.gitignore`

```
.DS_Store
.chezmoistate
```

### `.chezmoiignore`

Tells chezmoi to skip files that exist in the repo but shouldn't be applied to `$HOME`.

```
README.md
.gitignore
docs/**
```

### `README.md`

Documents:
- What the repo is and who it's for (one paragraph).
- External tool prerequisites with install links (RTK, bun, opencode).
- Fresh-machine bootstrap (numbered steps; see Workflows below).
- Day-to-day commands (`chezmoi add`, `edit`, `diff`, `apply`, `re-add`).

## Per-machine bootstrap config

Written by hand on each machine, not tracked in the repo:

```toml
# ~/.config/chezmoi/chezmoi.toml
sourceDir = "/Users/<username>/Desktop/dev/kai-config"
```

## Workflows

### Edit a tracked file (existing machine)

Option A — edit live, pull into repo:
1. Edit `~/.zshrc` directly in your editor.
2. `chezmoi re-add ~/.zshrc` (copies live → repo).
3. `cd $(chezmoi source-path)` → `git commit -am "..."` → `git push`.

Option B — edit via chezmoi:
1. `chezmoi edit ~/.zshrc` (opens source file in `$EDITOR`).
2. `chezmoi apply` (pushes change into live `~/.zshrc`).
3. Commit + push from the repo.

### Track a new file

1. `chezmoi add <path>` — chezmoi copies the file into the repo with correct naming (`dot_`, `private_`, `.tmpl` as appropriate).
2. Commit + push.

### Preview pending changes

`chezmoi diff` shows the diff between repo (source) and live (`$HOME`).

### Fresh-machine bootstrap

1. Install chezmoi: `brew install chezmoi`.
2. Install any external tools you actually use: bun, opencode, RTK (links in README).
3. Clone the repo: `git clone <url> ~/Desktop/dev/kai-config`.
4. Write `~/.config/chezmoi/chezmoi.toml` with `sourceDir = "<absolute path to clone>"`.
5. `chezmoi apply`.
6. `source ~/.zshrc`.
7. Restart Claude Code so it reloads `CLAUDE.md`.

## Validation

- After `chezmoi apply`, `chezmoi diff` produces no output.
- `~/.zshrc` and `~/.claude/CLAUDE.md` exist and match their repo counterparts byte-for-byte (no templating in v1).
- New shell loads without errors referencing missing tools (validates that the strip was complete).
- Cross-machine validation is deferred until the second machine is set up.

## Future (not v1)

- Track `~/.claude/settings.json` with chezmoi templates: hardcoded `/Users/<user>/...` paths become `{{ .chezmoi.homeDir }}/...`. Move ping-island and superset-hook commands accordingly.
- Track custom Claude artefacts: `~/.claude/agents/coden-ramsay.md`, `~/.claude/skills/ast-grep/`.
- Track VS Code: `code --list-extensions` output, `~/Library/Application Support/Code/User/settings.json`, `keybindings.json`.
- Track custom `~/.claude/hooks/` scripts (e.g. `rtk-rewrite.sh`).
- Migrate repo to chezmoi default `~/.local/share/chezmoi` if the per-machine toml becomes annoying.
- Encrypted secrets via age/gpg once anything sensitive needs tracking.
