# kai-config

Personal config snapshot for my macOS dev setup. Tracks `~/.zshrc`, my Claude Code global instructions (`~/.claude/CLAUDE.md`), a public-safe `settings.json` baseline, and a machine-local config template — for backup and cross-machine sync.

## Setup

```bash
git clone https://github.com/ChinKX/kai-config.git ~/Desktop/dev/kai-config
cd ~/Desktop/dev/kai-config
./install.sh
source ~/.zshrc
```

`install.sh` is idempotent. It **symlinks** the files you hand-edit (`CLAUDE.md`, via a relative link with no hardcoded home path) and **copies** the files apps write to (`zshrc`, `settings.json` — see [Claude settings](#claude-settings) for why). It also seeds `~/.claude/local.md` from `claude/local.md.example` and enables the pre-commit leak gate. Re-run it any time; an existing real file is backed up to `*.bak.<timestamp>` before being replaced, and an existing `settings.json` is left untouched.

Restart Claude Code to load the new `CLAUDE.md`.

## Machine-local config

`claude/CLAUDE.md` ends with `@~/.claude/local.md`, an import for machine-specific bits (tool paths, per-machine CLIs). That file is **deliberately not tracked here** — keep it out of this repo so the shared core stays portable and safe to publish. `install.sh` seeds it from the tracked template (`claude/local.md.example`) when absent; adjust it per machine afterwards.

RTK (Rust Token Killer) and its `PreToolUse` hook (`~/.claude/hooks/rtk-rewrite.sh`) are installed per-machine by the RTK tool — not tracked here — and the command auto-rewrite (`git status` → `rtk git status`) only works after RTK is set up.

## Claude settings

`claude/settings.json` is a **baseline** of the portable, public-safe slice of my Claude Code config: the public plugin marketplaces, `enabledPlugins`, `permissions.defaultMode`, and personal preference scalars (theme, effort level, etc.). Anything machine-specific, internal, or working-state is deliberately excluded.

Unlike `CLAUDE.md`, this file is **copied onto a machine, not symlinked.** Claude Code treats `~/.claude/settings.json` as a live, app-managed file — it writes runtime state there (notification toggles, `tui`, approved permissions). Symlinking it into the repo would let those writes dirty, and potentially leak into, this public repo. So the live file is a plain local copy; the tracked file is only the starting baseline.

Those excluded bits go **directly into the live `~/.claude/settings.json`** on each machine. That's safe precisely because the live file is a local copy, never tracked — machine-specific and internal config (the RTK hook, the status-line command, private plugin marketplaces, the whole `permissions.allow` list) can sit next to the baseline keys without ever reaching this repo.

> **Warning:** do NOT put user-level overrides in `~/.claude/settings.local.json`. Claude Code never loads that file — `settings.local.json` exists only at the *project* level (`./.claude/settings.local.json`). Anything placed in a user-level one is silently dead. (An earlier revision of this README recommended exactly that; everything in it — status line, RTK hook, allow-list — was inactive until merged back into `~/.claude/settings.json`.)

The allow-list is kept out of the baseline on purpose: it's working-state that accretes as you approve commands, and `permissions.allow` rules *union* across files — so a tracked rule could never be removed locally.

`permissions.defaultMode` ships as `"auto"` in the baseline: a freshly bootstrapped machine starts in auto mode (and, with the acceptance flags above, without the opt-in dialog). Auto mode is classifier-gated rather than blanket auto-approve, but if a machine should prompt for everything, flip it to `"default"` in the live `~/.claude/settings.json`.

A `.githooks/pre-commit` leak gate blocks commits whose staged files contain secrets, tokens, or hardcoded home paths, as a backstop. Enable it per machine with `git config core.hooksPath .githooks` (`install.sh` does this, and copies `settings.json` into place if it is not already present).

## Plugins

`claude/CLAUDE.md` defers code-style guidance to the `karpathy-guidelines` skill. Install it once per machine, from inside Claude Code:

```
/plugin marketplace add multica-ai/andrej-karpathy-skills
/plugin install andrej-karpathy-skills@karpathy-skills
```

If the skill isn't installed, the same principles are inlined in `CLAUDE.md`, so nothing breaks.

## External tools

Some of my `~/.claude/` and shell setup is installed by separate tools and is **not tracked here**. On a fresh machine, install the ones you use — their own installers lay down (or re-add) the relevant files:

- **[Argent](https://github.com/software-mansion/argent)** — `npx @swmansion/argent init` installs the `argent-*` skills, the `~/.claude/rules/argent.md` always-on rule, and the `argent-environment-inspector` agent (iOS/Android agent tooling). Deliberately not tracked here — re-run `init` per machine, and to update the rule.
- **RTK (Rust Token Killer)** — installed per-machine; provides `~/.claude/hooks/rtk-rewrite.sh` and its `PreToolUse` hook (see [Machine-local config](#machine-local-config)).
- **bun / opencode** — their installers re-add their own `~/.zshrc` lines.
