# Tribal

Git-backed tribal knowledge for teams. Capture, search, and share the knowledge that lives in people's heads.

## What is Tribal?

Tribal is a bash CLI that stores team knowledge as Markdown files with YAML frontmatter in a git repo. It provides ranked search, security filtering, and integrates with LLM coding assistants (Claude Code, Cursor, Codex) so your AI tools can automatically search and contribute to your team's knowledge base.

## Quick Start

```bash
# Initialize in current directory
./tribal init

# Add knowledge
./tribal add --title "Docker DNS on Linux" \
  --category debugging \
  --tags "docker,dns,linux" \
  --confidence high \
  --summary "Fix DNS in containers by configuring daemon.json" \
  --body "## Problem
DNS fails inside Docker containers on systemd-resolved hosts.

## Solution
Add dns entries to /etc/docker/daemon.json and restart Docker."

# Search
./tribal search "docker dns"

# List all entries
./tribal list

# Filter by category
./tribal list --category debugging
```

## Installation

### Option A: Clone and use directly

```bash
git clone <your-repo-url> ~/.tribal
export TRIBAL_PATH=~/.tribal
export PATH="$TRIBAL_PATH:$PATH"
tribal init
```

### Option B: Use the installer

```bash
TRIBAL_REPO_URL=git@github.com:yourorg/tribal.git bash install.sh
```

The installer clones to `~/.tribal` and creates a wrapper script on your PATH with automatic background updates.

## Commands

| Command | Description |
|---------|-------------|
| `tribal init [path]` | Initialize a new knowledge base |
| `tribal add [options]` | Add a knowledge entry (interactive if no flags) |
| `tribal search <query>` | Ranked search across all entries |
| `tribal list [--category CAT]` | List entries with optional filter |
| `tribal update <slug>` | Edit an entry in $EDITOR |
| `tribal verify <slug>` | Mark an entry as verified |
| `tribal reindex` | Rebuild INDEX.md |
| `tribal stats` | Show knowledge base statistics |
| `tribal link [--claude\|--cursor\|--codex\|--all]` | Install LLM skill files |
| `tribal help [command]` | Show help |
| `tribal version` | Show version |

## Entry Schema

Entries are Markdown files in `entries/` with YAML frontmatter:

```yaml
---
title: "Descriptive Title"
slug: descriptive-title
category: debugging          # environment|debugging|architecture|process|tooling|testing|deployment|security
tags: [docker, dns, linux]
confidence: high             # high|medium|low
author: Jane Smith
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: Jane Smith
summary: "One-line summary for scanning"
---

## Problem
...

## Solution
...

## Context
...
```

## Search Ranking

Results are ranked by a composite score:
- **Tag match**: weight 10
- **Title match**: weight 7
- **Body match**: weight 3
- **Recency bonus**: +2 if modified in last 30 days, +1 if last 90 days
- **Confidence multiplier**: high=1.0, medium=0.7, low=0.4

## Security

A built-in security filter scans entries for potential secrets before committing:
- API keys (OpenAI, AWS, GitHub PATs)
- Connection strings (MongoDB, PostgreSQL)
- Private keys
- JWTs
- Password/token assignments

Use `--force` to bypass if you get a false positive. The pre-commit hook also runs the security filter automatically.

## LLM Integration

Run `tribal link --all` to install skill files for:

- **Claude Code**: `~/.claude/skills/tribal.md`
- **Cursor**: `.cursorrules` in project root
- **Codex**: `codex.md` in project root

The skill files instruct LLM assistants to:
1. Search tribal knowledge before investigating errors
2. Capture new knowledge after resolving non-trivial issues
3. Update existing entries instead of creating duplicates

## Chat Sync (Optional)

Tribal can automatically extract knowledge from Slack or Microsoft Teams via a GitHub Action that runs every 15 minutes.

Modes:
- **Channel mode**: Monitor a dedicated knowledge channel
- **Reaction mode**: Watch for a specific emoji reaction on messages

Configure in `tribal.config.yml` and set the required secrets in your GitHub repo settings. See `chat-sync/sync.sh` for details.

## Testing

```bash
bats tests/
```

Requires [bats-core](https://github.com/bats-core/bats-core).

## License

AGPL-3.0-or-later
