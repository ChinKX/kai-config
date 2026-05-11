# kai-config

Personal config snapshot for my macOS dev setup. Tracks two files:

- `zshrc` — my `~/.zshrc` minus any third-party tool blocks (bun, opencode).
- `claude/CLAUDE.md` — my global Claude Code instructions (`~/.claude/CLAUDE.md`), minus the `@RTK.md` include.

Used for backup, cross-machine sync, and public showcase. Sync is manual (`cp` both directions) — see workflows below.

## External tool prerequisites

`zshrc` was stripped of these tools' wiring before commit. Reinstall them on a fresh machine and their installers append their own lines back to `~/.zshrc`:

- [bun](https://bun.sh) — `curl -fsSL https://bun.sh/install | bash`
- [opencode](https://opencode.ai) — see project install docs
- RTK (Rust Token Killer) — installed separately; not publicly available

`CLAUDE.md` was stripped of the `@RTK.md` include. Restore your own RTK reference doc at `~/.claude/RTK.md` and add `@RTK.md` back to `~/.claude/CLAUDE.md` if you want it sourced.

### Other tools the tracked `zshrc` still depends on

These are NOT stripped (they use `$HOME` or guarded paths) but the tracked `zshrc` will error or silently degrade if they're missing on a fresh machine. Install them too for a fully working shell:

- **Homebrew** — `/opt/homebrew/bin/brew` (guarded `-f` check, silent if absent)
- **Rust / Cargo** — `. "$HOME/.cargo/env"` is unguarded; prints `no such file` on every shell open if Rust isn't installed
- **fzf** — `eval "$(fzf --zsh)"` errors silently if fzf isn't on PATH
- **zoxide** — `eval "$(zoxide init --cmd cd zsh)"` errors silently if zoxide isn't on PATH
- **neovim** — `alias vim='nvim'` (harmless until `vim` is invoked)
- **Powerlevel10k** — auto-installed by zinit on first shell load (no manual install needed)

## Fresh-machine restore

```bash
# 1. Clone
git clone <repo-url> ~/Desktop/dev/kai-config

# 2. Restore zshrc
cp ~/Desktop/dev/kai-config/zshrc ~/.zshrc

# 3. Restore CLAUDE.md
mkdir -p ~/.claude
cp ~/Desktop/dev/kai-config/claude/CLAUDE.md ~/.claude/CLAUDE.md

# 4. Install external tools you want (bun, opencode, RTK)
#    Their installers append their own lines to ~/.zshrc.

# 5. Reload
source ~/.zshrc

# 6. Restart Claude Code to pick up the new CLAUDE.md.
```

## Source-machine sync (live → repo)

After editing `~/.zshrc` or `~/.claude/CLAUDE.md` on your working machine:

```bash
# zshrc: copy, then strip the external-tool blocks.
cp ~/.zshrc ~/Desktop/dev/kai-config/zshrc
sed -i '' '/^# opencode$/,$d' ~/Desktop/dev/kai-config/zshrc

# CLAUDE.md: copy, then strip the @RTK.md include line.
cp ~/.claude/CLAUDE.md ~/Desktop/dev/kai-config/claude/CLAUDE.md
sed -i '' '/^@RTK\.md$/d' ~/Desktop/dev/kai-config/claude/CLAUDE.md

# Sanity-check 1: no external-tool refs leaked.
grep -nE 'opencode|bun|BUN_INSTALL|@RTK' ~/Desktop/dev/kai-config/zshrc ~/Desktop/dev/kai-config/claude/CLAUDE.md
# Expected: no output.

# Sanity-check 2: line count dropped by the expected amount.
#   ~/.zshrc should lose ~9 lines (the three trailing blocks: opencode, bun completions, bun env).
#   If it dropped more, the sed deleted config you added AFTER the bun block too.
wc -l ~/.zshrc ~/Desktop/dev/kai-config/zshrc

# Commit (explicit paths — avoid -am which would also stage edits to docs/, README, etc).
cd ~/Desktop/dev/kai-config
git diff
git add zshrc claude/CLAUDE.md
git commit -m "..."
git push
```

> **Footgun on the `zshrc` `sed`:** the command deletes from the first `# opencode` line to end of file. If you've added new config *after* the opencode/bun blocks in your live `~/.zshrc`, this silently nukes that new config too — the grep sanity-check won't catch it because nothing was leaked. The `wc -l` check above is the real guard: if more than ~9 lines disappeared, copy `~/.zshrc` manually and delete the three blocks by hand.
