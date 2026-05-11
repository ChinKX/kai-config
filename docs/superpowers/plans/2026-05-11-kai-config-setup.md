# kai-config v1 MVP Setup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate the `kai-config` repo at `~/Desktop/dev/kai-config` with stripped, public-shareable copies of `~/.zshrc` and `~/.claude/CLAUDE.md`, plus a `.gitignore` and `README.md`. Commit each logical unit. Verify the repo contains no hardcoded user paths and no external-tool references.

**Architecture:** Pure backup repo — plain copies in git, no sync tool, no symlinks, no scripts. Manual `cp` in both directions per the README. Tracked filenames have no dot prefix (e.g. `zshrc`, not `.zshrc`).

**Tech Stack:** git, zsh, macOS, plain text editing.

**Prereqs already done:**
- Git repo initialised at `~/Desktop/dev/kai-config` (branch `main`, root commit + spec revision committed).
- Design spec at `docs/superpowers/specs/2026-05-11-kai-config-design.md`.

---

## Files this plan creates

| Repo path | Source | Notes |
|---|---|---|
| `.gitignore` | new | Ignores `.DS_Store`. |
| `zshrc` | `~/.zshrc` minus opencode + bun blocks | Plain file, no dot prefix. |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` minus `@RTK.md` line | Plain file inside new `claude/` dir. |
| `README.md` | new | Purpose, prereqs, restore + sync workflows. |

---

## Task 1: Add `.gitignore`

**Files:**
- Create: `~/Desktop/dev/kai-config/.gitignore`

- [ ] **Step 1: Create the file**

Write to `~/Desktop/dev/kai-config/.gitignore`:

```
.DS_Store
```

- [ ] **Step 2: Verify**

Run from anywhere:
```bash
cat ~/Desktop/dev/kai-config/.gitignore
```
Expected output (one line):
```
.DS_Store
```

- [ ] **Step 3: Commit**

```bash
git -C ~/Desktop/dev/kai-config add .gitignore
git -C ~/Desktop/dev/kai-config commit -m "chore: add .gitignore for .DS_Store"
```

---

## Task 2: Copy and strip `~/.zshrc` into `zshrc`

**Files:**
- Source: `~/.zshrc` (do not modify)
- Create: `~/Desktop/dev/kai-config/zshrc`

- [ ] **Step 1: Copy the file as-is**

```bash
cp ~/.zshrc ~/Desktop/dev/kai-config/zshrc
```

- [ ] **Step 2: Inspect what's at the bottom**

```bash
tail -n 15 ~/Desktop/dev/kai-config/zshrc
```
Expected output (or similar — the three blocks to remove):
```
# zprof

# opencode
export PATH=/Users/kaixiang.chin/.opencode/bin:$PATH

# bun completions
[ -s "/Users/kaixiang.chin/.bun/_bun" ] && source "/Users/kaixiang.chin/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

- [ ] **Step 3: Strip the three external-tool blocks**

Open `~/Desktop/dev/kai-config/zshrc` in your editor and delete every line from `# opencode` through the end of file. After deletion, the file should end with `# zprof` (followed by a single trailing newline).

If you prefer a one-shot command, use `sed` to delete from the first `# opencode` line through end of file:

```bash
sed -i '' '/^# opencode$/,$d' ~/Desktop/dev/kai-config/zshrc
```

- [ ] **Step 4: Verify the strip**

```bash
grep -nE 'opencode|bun|BUN_INSTALL' ~/Desktop/dev/kai-config/zshrc
```
Expected output: nothing (exit code 1).

```bash
tail -n 3 ~/Desktop/dev/kai-config/zshrc
```
Expected output (last non-empty line should be `# zprof`):
```

# zprof

```

- [ ] **Step 5: Verify no hardcoded user paths remain**

```bash
grep -nE '/Users/' ~/Desktop/dev/kai-config/zshrc
```
Expected output: nothing (exit code 1).

If anything matches, investigate — the spec assumes zero hardcoded paths in the tracked file.

---

## Task 3: Copy and clean `~/.claude/CLAUDE.md` into `claude/CLAUDE.md`

**Files:**
- Source: `~/.claude/CLAUDE.md` (do not modify)
- Create: `~/Desktop/dev/kai-config/claude/CLAUDE.md`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p ~/Desktop/dev/kai-config/claude
```

- [ ] **Step 2: Copy the file as-is**

```bash
cp ~/.claude/CLAUDE.md ~/Desktop/dev/kai-config/claude/CLAUDE.md
```

- [ ] **Step 3: Inspect the last line**

```bash
tail -n 3 ~/Desktop/dev/kai-config/claude/CLAUDE.md
```
Expected output (the last non-empty line should be `@RTK.md`):
```
The goal is natural, collaborative problem-solving where I can challenge your thinking and you can challenge mine.

@RTK.md
```

- [ ] **Step 4: Remove the `@RTK.md` line**

```bash
sed -i '' '/^@RTK\.md$/d' ~/Desktop/dev/kai-config/claude/CLAUDE.md
```

- [ ] **Step 5: Verify the strip**

```bash
grep -n '@RTK' ~/Desktop/dev/kai-config/claude/CLAUDE.md
```
Expected output: nothing (exit code 1).

```bash
tail -n 3 ~/Desktop/dev/kai-config/claude/CLAUDE.md
```
Expected output (no more `@RTK.md`):
```

The goal is natural, collaborative problem-solving where I can challenge your thinking and you can challenge mine.

```

---

## Task 4: Commit the two tracked files

- [ ] **Step 1: Stage both files**

```bash
git -C ~/Desktop/dev/kai-config add zshrc claude/CLAUDE.md
```

- [ ] **Step 2: Sanity-check what's about to be committed**

```bash
git -C ~/Desktop/dev/kai-config status
```
Expected output (paths under "Changes to be committed"):
```
new file:   claude/CLAUDE.md
new file:   zshrc
```

- [ ] **Step 3: Verify no hardcoded user paths in staged files**

```bash
git -C ~/Desktop/dev/kai-config diff --cached --name-only | xargs -I{} grep -lnE '/Users/' ~/Desktop/dev/kai-config/{} 2>/dev/null
```
Expected output: nothing (exit code 1).

- [ ] **Step 4: Commit**

```bash
git -C ~/Desktop/dev/kai-config commit -m "feat: track zshrc and CLAUDE.md (stripped of external-tool refs)"
```

---

## Task 5: Write `README.md`

**Files:**
- Create: `~/Desktop/dev/kai-config/README.md`

- [ ] **Step 1: Write the file**

Write to `~/Desktop/dev/kai-config/README.md`:

````markdown
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
````

- [ ] **Step 2: Verify**

```bash
head -n 5 ~/Desktop/dev/kai-config/README.md
```
Expected: starts with `# kai-config`.

- [ ] **Step 3: Commit**

```bash
git -C ~/Desktop/dev/kai-config add README.md
git -C ~/Desktop/dev/kai-config commit -m "docs: add README with restore and sync workflows"
```

---

## Task 6: End-to-end validation

- [ ] **Step 1: Repo tree matches the spec**

```bash
cd ~/Desktop/dev/kai-config
ls -A
```
Expected output (order may vary):
```
.git
.gitignore
README.md
claude
docs
zshrc
```

```bash
ls claude
```
Expected:
```
CLAUDE.md
```

- [ ] **Step 2: No external-tool references in tracked files**

```bash
grep -rnE 'opencode|bun|BUN_INSTALL|@RTK' ~/Desktop/dev/kai-config/zshrc ~/Desktop/dev/kai-config/claude/CLAUDE.md
```
Expected output: nothing (exit code 1).

- [ ] **Step 3: No hardcoded user paths in tracked content files**

```bash
grep -rnE '/Users/' ~/Desktop/dev/kai-config --exclude-dir=.git --exclude-dir=docs
```
Expected output: nothing (exit code 1). (Docs are excluded because the spec and plan legitimately reference user paths for clarity.)

- [ ] **Step 4: Git tree is clean**

```bash
git -C ~/Desktop/dev/kai-config status
```
Expected output:
```
On branch main
nothing to commit, working tree clean
```

- [ ] **Step 5: Review commit history**

```bash
git -C ~/Desktop/dev/kai-config log --oneline
```
Expected output (6 commits, newest first):
```
<hash> docs: add README with restore and sync workflows
<hash> feat: track zshrc and CLAUDE.md (stripped of external-tool refs)
<hash> chore: add .gitignore for .DS_Store
<hash> docs: add implementation plan for kai-config v1 MVP
<hash> docs: revise spec to pure backup repo MVP
<hash> docs: add kai-config design spec
```

---

## Out of scope (do NOT do in this plan)

- Do NOT run any sync tool (chezmoi, stow). Not used in v1.
- Do NOT create symlinks from `~/.zshrc` or `~/.claude/CLAUDE.md` into the repo. Manual cp only.
- Do NOT add a GitHub remote. The user will configure that separately if desired.
- Do NOT modify the live `~/.zshrc` or `~/.claude/CLAUDE.md`. This plan reads from them and writes to the repo only.
- Do NOT track `~/.claude/settings.json`, `agents/`, `skills/`, `hooks/`, or VS Code config. Future work.
