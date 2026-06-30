# kai-config

Personal config snapshot for my macOS dev setup. Tracks `~/.zshrc` and my Claude Code global instructions (`~/.claude/CLAUDE.md`) for backup and cross-machine sync.

## Setup

```bash
git clone https://github.com/ChinKX/kai-config.git ~/Desktop/dev/kai-config
cp ~/Desktop/dev/kai-config/zshrc ~/.zshrc

mkdir -p ~/.claude
# Symlink (not copy) so Claude's own edits and git pulls stay in lockstep — no drift.
ln -sf ~/Desktop/dev/kai-config/claude/CLAUDE.md ~/.claude/CLAUDE.md

source ~/.zshrc
```

Restart Claude Code to load the new `CLAUDE.md`.

## Machine-local config

`claude/CLAUDE.md` ends with `@~/.claude/local.md`, an import for machine-specific bits (tool paths, per-machine CLIs). That file is **deliberately not tracked here** — keep it out of this repo so the shared core stays portable and safe to publish. Create a stub on each machine so the import resolves:

```bash
touch ~/.claude/local.md   # then add machine-specific notes as needed
```

## Claude settings

`claude/settings.json` holds the portable, public-safe slice of my Claude Code config: the public plugin marketplaces, `enabledPlugins`, `permissions.defaultMode`, and personal preference scalars (theme, effort level, etc.). Anything machine-specific, internal, or working-state is deliberately excluded.

Those excluded bits live in `~/.claude/settings.local.json` — an untracked (gitignored) override that Claude Code merges *over* `settings.json`. It holds the RTK hook, the status-line command, private plugin marketplaces, the permission-skip flags, and the whole `permissions.allow` list.

The allow-list is kept local on purpose: it's working-state that accretes as you approve commands; `permissions.allow` rules *union* across files (so a tracked rule could never be removed by a local override); and `~/.claude/settings.json` is a symlink to this tracked file — so an "always allow" written there could otherwise land in this public repo.

A `.githooks/pre-commit` leak gate blocks commits whose staged files contain internal markers, as a backstop. Enable it per machine with `git config core.hooksPath .githooks` (the planned install script will do this, and wire the symlink).

## Plugins

`claude/CLAUDE.md` defers code-style guidance to the `karpathy-guidelines` skill. Install it once per machine, from inside Claude Code:

```
/plugin marketplace add forrestchang/andrej-karpathy-skills
/plugin install andrej-karpathy-skills@karpathy-skills
```

If the skill isn't installed, the same principles are inlined in `CLAUDE.md`, so nothing breaks.
