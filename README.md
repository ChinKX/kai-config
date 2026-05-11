# kai-config

Personal config snapshot for my macOS dev setup. Tracks `~/.zshrc` and my Claude Code global instructions (`~/.claude/CLAUDE.md`) for backup and cross-machine sync.

## Setup

```bash
git clone https://github.com/ChinKX/kai-config.git ~/Desktop/dev/kai-config
cp ~/Desktop/dev/kai-config/zshrc ~/.zshrc
mkdir -p ~/.claude
cp ~/Desktop/dev/kai-config/claude/CLAUDE.md ~/.claude/CLAUDE.md
source ~/.zshrc
```

Restart Claude Code to load the new `CLAUDE.md`.
