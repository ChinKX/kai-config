# kai-config

Personal config snapshot for my macOS dev setup. Tracks `~/.zshrc` and my Claude Code global instructions (`~/.claude/CLAUDE.md`) for backup and cross-machine sync.

## Setup

```bash
git clone https://github.com/ChinKX/kai-config.git ~/Desktop/dev/kai-config
cd ~/Desktop/dev/kai-config
./install.sh
source ~/.zshrc
```

`install.sh` is idempotent. It **symlinks** the files you hand-edit (`CLAUDE.md`, via a relative link with no hardcoded home path) and **copies** the files apps write to (`zshrc`, `settings.json` — see [Claude settings](#claude-settings) for why). It also seeds the `~/.claude/local.md` stub and enables the pre-commit leak gate. Re-run it any time; an existing real file is backed up to `*.bak.<timestamp>` before being replaced, and an existing `settings.json` is left untouched.

Restart Claude Code to load the new `CLAUDE.md`.

## Machine-local config

`claude/CLAUDE.md` ends with `@~/.claude/local.md`, an import for machine-specific bits (tool paths, per-machine CLIs). That file is **deliberately not tracked here** — keep it out of this repo so the shared core stays portable and safe to publish. Seed it on each machine from the tracked template:

```bash
cp ~/Desktop/dev/kai-config/claude/local.md.example ~/.claude/local.md   # then adjust
```

RTK (Rust Token Killer) and its `PreToolUse` hook (`~/.claude/hooks/rtk-rewrite.sh`) are installed per-machine by the RTK tool — not tracked here — and the command auto-rewrite (`git status` → `rtk git status`) only works after RTK is set up.

## Claude settings

`claude/settings.json` is a **baseline** of the portable, public-safe slice of my Claude Code config: the public plugin marketplaces, `enabledPlugins`, `permissions.defaultMode`, and personal preference scalars (theme, effort level, etc.). Anything machine-specific, internal, or working-state is deliberately excluded.

Unlike `CLAUDE.md`, this file is **copied onto a machine, not symlinked.** Claude Code treats `~/.claude/settings.json` as a live, app-managed file — it writes runtime state there (notification toggles, `tui`, approved permissions). Symlinking it into the repo would let those writes dirty, and potentially leak into, this public repo. So the live file is a plain local copy; the tracked file is only the starting baseline.

Those excluded bits live in `~/.claude/settings.local.json` — an untracked (gitignored) override that Claude Code merges *over* `settings.json`. It holds the RTK hook, the status-line command, private plugin marketplaces, the permission-skip flags, and the whole `permissions.allow` list.

The allow-list is kept local on purpose: it's working-state that accretes as you approve commands, and `permissions.allow` rules *union* across files — so a tracked rule could never be removed by a local override.

A `.githooks/pre-commit` leak gate blocks commits whose staged files contain secrets, tokens, or hardcoded home paths, as a backstop. Enable it per machine with `git config core.hooksPath .githooks` (the planned install script does this, and copies `settings.json` into place).

## Plugins

`claude/CLAUDE.md` defers code-style guidance to the `karpathy-guidelines` skill. Install it once per machine, from inside Claude Code:

```
/plugin marketplace add forrestchang/andrej-karpathy-skills
/plugin install andrej-karpathy-skills@karpathy-skills
```

If the skill isn't installed, the same principles are inlined in `CLAUDE.md`, so nothing breaks.
