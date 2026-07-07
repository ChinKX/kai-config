# kai-config

Personal config for my macOS dev setup: `~/.zshrc`, Claude Code global instructions (`~/.claude/CLAUDE.md`), a public-safe `settings.json` baseline, and a machine-local template — for backup and cross-machine sync.

## Setup

```bash
git clone https://github.com/ChinKX/kai-config.git ~/Desktop/dev/kai-config
cd ~/Desktop/dev/kai-config
./install.sh
source ~/.zshrc
```

`install.sh` is idempotent: **symlinks** the files you hand-edit (`CLAUDE.md`), **copies** the files apps write to (`zshrc`, `settings.json` — see [Claude settings](#claude-settings)), seeds `~/.claude/local.md` from the template, and enables the pre-commit leak gate. Existing real files are backed up to `*.bak.<timestamp>`; an existing `settings.json` is left untouched. Restart Claude Code to load the new `CLAUDE.md`.

## Machine-local config

`claude/CLAUDE.md` ends with `@~/.claude/local.md`, an import for machine-specific bits (tool paths, per-machine CLIs). It is deliberately untracked so the shared core stays portable and publishable; `install.sh` seeds it from `claude/local.md.example`.

## Claude settings

`claude/settings.json` is a **baseline** of the portable, public-safe slice: public plugin marketplaces, `enabledPlugins`, `permissions.defaultMode`, and preference scalars. Anything machine-specific, internal, or working-state is excluded.

The baseline is **copied, not symlinked**: Claude Code writes runtime state into `~/.claude/settings.json` (notification toggles, approved permissions), and a symlink would let those writes dirty — or leak into — this public repo. The live file is a plain local copy.

Machine-specific and internal config (the RTK hook, status-line command, private marketplaces, the `permissions.allow` list) therefore goes **directly into the live `~/.claude/settings.json`**. The allow-list stays out of the baseline: it accretes as you approve commands, and allow rules union across files, so a tracked rule could never be removed locally.

> **Warning:** never put user-level overrides in `~/.claude/settings.local.json` — Claude Code does not load that file. `settings.local.json` exists only at the project level (`./.claude/settings.local.json`); a user-level one is silently dead. An earlier revision of this README recommended exactly that.

`permissions.defaultMode` ships as `"auto"` (classifier-gated, not blanket auto-approve), and the acceptance flags suppress the one-time opt-in dialogs. Flip a machine to `"default"` in the live file if it should prompt for everything.

A `.githooks/pre-commit` leak gate blocks staged secrets, tokens, and hardcoded home paths. `install.sh` enables it (`git config core.hooksPath .githooks`).

## Plugins

`claude/CLAUDE.md` defers code-style guidance to the `karpathy-guidelines` skill (the same principles are inlined in `CLAUDE.md` as a fallback). Install once per machine, from inside Claude Code:

```
/plugin marketplace add multica-ai/andrej-karpathy-skills
/plugin install andrej-karpathy-skills@karpathy-skills
```

## External tools

These lay down their own `~/.claude/` or shell files and are not tracked here — install per machine:

- **[Argent](https://github.com/software-mansion/argent)** — `npx @swmansion/argent init` installs the `argent-*` skills, the `~/.claude/rules/argent.md` rule, and the `argent-environment-inspector` agent. Re-run `init` to update.
- **RTK (Rust Token Killer)** — installs `~/.claude/hooks/rtk-rewrite.sh` and its `PreToolUse` hook; the command auto-rewrite (`git status` → `rtk git status`) only works after RTK is set up.
- **bun / opencode** — their installers re-add their own `~/.zshrc` lines.
