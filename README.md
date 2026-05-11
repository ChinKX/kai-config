# kai-config

Personal config snapshot for my macOS dev setup. Tracks two files:

- `zshrc` — my `~/.zshrc` minus any third-party tool blocks (bun, opencode).
- `claude/CLAUDE.md` — my global Claude Code instructions (`~/.claude/CLAUDE.md`), minus the `@RTK.md` include.

Used for backup, cross-machine sync, and public showcase. Sync is manual (`cp` both directions) — see workflows below.

## External tool prerequisites

These tools are referenced by my live config but not tracked here. Install them on a new machine and their installers re-add their own shell lines.

- [bun](https://bun.sh) — `curl -fsSL https://bun.sh/install | bash`
- [opencode](https://opencode.ai) — see project install docs
- [RTK (Rust Token Killer)](https://github.com/) — see project install docs

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

# Sanity-check.
grep -nE 'opencode|bun|BUN_INSTALL|@RTK' ~/Desktop/dev/kai-config/zshrc ~/Desktop/dev/kai-config/claude/CLAUDE.md
# Expected: no output.

# Commit.
cd ~/Desktop/dev/kai-config
git diff
git commit -am "..."
git push
```

> **Note on the `sed` for `zshrc`:** the command deletes from the first `# opencode` line to end of file. This assumes opencode, bun completions, and the bun env block are still the trailing blocks of `~/.zshrc`. If you've added new config after them, copy manually and delete the three blocks by hand instead.
