# Tribal

Your AI coding assistant already knows how to debug, refactor, and write code. What it doesn't know is *your team's* way of doing things — the workarounds, the gotchas, the "oh we tried that and here's what actually works." That's tribal knowledge, and it's usually trapped in people's heads or buried in Slack threads.

Tribal fixes this. It's a shared knowledge base that your LLM coding agents (Claude Code, Cursor, Codex) **automatically read from and write to** as you work. When your AI hits an error someone on your team already solved, it finds the answer. When it helps you solve something new, it captures it for the next person.

## How It Works

```
Developer + AI agent working on code
         │
         ├─ AI hits an error ──→ tribal search "error text" ──→ finds team's known fix ──→ applies it
         │
         └─ AI solves something new ──→ tribal add ──→ captured for the whole team
         │
         └─ git push ──→ knowledge syncs to everyone
```

Your LLM agent does this automatically. You don't run these commands — your AI does, as part of its normal workflow, because tribal installs a skill file that teaches it when to search and when to capture.

## Setup for Your Team

### 1. Org leader: Fork/clone this repo as your team's knowledge base

```bash
# Create your org's tribal repo
gh repo create yourorg/tribal --template mansoorsiddiqui/tribal --private
```

Configure `tribal.config.yml` for your team (categories, chat sync if desired), seed it with a few entries your team already knows, and push.

### 2. Team members: One-liner to set up

Paste this into your AI coding agent (Claude Code, Cursor, Codex):

```
Read https://github.com/yourorg/tribal/blob/main/INSTALL_LLM.md and follow every step to install our team's tribal knowledge base on my machine.
```

That's it. Your AI reads the instructions, clones the repo, installs the CLI, hooks itself up, and starts using your team's knowledge automatically.

## What Happens After Setup

**Your AI agent will automatically:**

- **Search before debugging** — Before investigating any error, it runs `tribal search` to check if someone on your team already solved it
- **Search before proposing patterns** — Before suggesting architecture or conventions, it checks what your team has documented
- **Capture after resolving** — After a non-trivial debugging session, it writes up the problem and solution as a new entry
- **Update stale entries** — If it finds an outdated entry, it updates it rather than creating a duplicate
- **Sync via git** — All knowledge is committed and pushed, so everyone's AI has access

**You don't have to think about it.** The knowledge base grows as your team works.

## What's Inside

```
entries/              ← Knowledge entries (Markdown + YAML frontmatter)
INDEX.md              ← Auto-generated index for fast LLM scanning
tribal                ← CLI that your AI agent calls
skills/               ← Instruction files that teach LLMs the workflow
tribal.config.yml     ← Configuration
chat-sync/            ← Optional: extract knowledge from Slack/Teams
```

Each entry looks like:

```yaml
---
title: "Docker DNS Fails on Linux with systemd-resolved"
category: debugging
tags: [docker, dns, linux, systemd-resolved]
confidence: high
summary: "Configure daemon.json with explicit DNS servers"
---

## Problem
Containers can't resolve DNS on Ubuntu/Fedora hosts using systemd-resolved...

## Solution
Add dns config to /etc/docker/daemon.json...
```

## Per-Project Control: `hook` and `unhook`

The global skill files (`tribal link --all`) make tribal active in every session. But you can also control it per-project:

**Opt a project in** — reinforces tribal usage and commits the instructions so every team member's AI gets them:

```bash
cd ~/myproject
tribal hook claude        # Adds tribal instructions to CLAUDE.md
tribal hook cursor        # Adds tribal instructions to .cursorrules
tribal hook               # All targets at once
git add CLAUDE.md && git commit -m "Enable tribal knowledge"
```

This injects a managed block into the project's `CLAUDE.md` (or `.cursorrules` / `codex.md`) with explicit instructions for the AI to search and capture tribal knowledge. The block is clearly marked and idempotent — running `hook` twice won't duplicate it.

**Opt a project out** — tells the AI to skip tribal for this repo:

```bash
cd ~/myproject
tribal unhook claude      # Replaces the block with "do NOT use tribal here"
tribal unhook             # All targets at once
git add CLAUDE.md && git commit -m "Disable tribal knowledge"
```

This replaces any existing tribal block with an opt-out instruction. The AI will see "do NOT use tribal" and skip it for that project.

**Switching back:** `tribal hook` after `tribal unhook` cleanly replaces the opt-out with the full instructions again.

## CLI Reference

Your AI uses these commands — you typically don't need to run them manually:

| Command | What the AI uses it for |
|---------|------------------------|
| `tribal search <query>` | Check if the team already knows about this |
| `tribal add --title "..." ...` | Capture new knowledge after solving something |
| `tribal list` | Browse what the team knows |
| `tribal update <slug>` | Fix or expand an existing entry |
| `tribal verify <slug>` | Confirm an entry is still accurate |
| `tribal reindex` | Rebuild the index (also runs on pre-commit) |
| `tribal stats` | See knowledge base health |
| `tribal link` | Install global LLM skill files (once per machine) |
| `tribal hook [target]` | Add tribal instructions to this project's CLAUDE.md / .cursorrules |
| `tribal unhook [target]` | Opt this project out of tribal knowledge |

## Chat Sync (Optional)

Tribal can also pull knowledge from Slack or Microsoft Teams automatically via a GitHub Action. Configure channels or a reaction emoji in `tribal.config.yml`, and messages get extracted, structured by an LLM, and added as entries.

## Security

A built-in filter blocks entries containing API keys, passwords, connection strings, private keys, and JWTs. The pre-commit hook enforces this too. Use `--force` for false positives.

## License

AGPL-3.0-or-later
