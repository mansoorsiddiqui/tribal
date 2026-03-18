# Tribal Implementation Plan

## Overview

Tribal is a git-backed CLI tool for capturing, searching, and sharing team knowledge ("tribal knowledge"). It stores entries as Markdown files with YAML frontmatter, provides ranked search, integrates with LLM coding assistants (Claude Code, Cursor, Codex), and optionally syncs knowledge from Slack/Teams via a GitHub Action.

## File Tree

```
/home/user/tribal/
├── tribal                          # Main CLI script (bash, ~700 lines)
├── install.sh                      # Clone + thin PATH wrapper with auto-update
├── .hooks/
│   └── pre-commit                  # Security filter + INDEX.md freshness
├── entries/
│   └── examples/
│       ├── node-version-m1-mac.md
│       ├── docker-dns-resolution-linux.md
│       ├── postgres-connection-pooling.md
│       ├── ci-flaky-test-retry-pattern.md
│       └── git-rebase-vs-merge-policy.md
├── skills/
│   ├── claude-code.md              # Claude Code skill file
│   ├── cursor.md                   # Cursor rules
│   └── codex.md                    # Codex config
├── .github/
│   └── workflows/
│       └── chat-sync.yml           # GitHub Action for chat integration
├── chat-sync/
│   └── sync.sh                     # Chat sync logic (bash + curl + jq)
├── tribal.config.yml               # Config schema with defaults
├── INDEX.md                        # Auto-generated LLM-friendly index
├── INSTALL_LLM.md                  # LLM-readable bootstrap instructions
├── SPEC.md                         # Full specification
├── README.md                       # Human-readable docs
├── LICENSE                         # AGPL-3.0
├── .gitignore
└── tests/
    ├── test_helper/
    │   └── common-setup.bash
    ├── cli_init.bats
    ├── cli_add.bats
    ├── cli_search.bats
    ├── cli_list.bats
    ├── cli_update.bats
    ├── cli_verify.bats
    ├── cli_reindex.bats
    ├── cli_stats.bats
    ├── cli_link.bats
    ├── security_filter.bats
    ├── index_generation.bats
    └── integration.bats
```

## Implementation Phases

### Phase 1: CLI Foundation
**Files:** `tribal`, `.hooks/pre-commit`, `.gitignore`, `LICENSE`

The `tribal` script is the critical path — everything else depends on it. Single bash file (~700 lines) with these commands:

| Command | Description | Complexity |
|---------|-------------|------------|
| `init` | Create directory structure, install hook, init git | S |
| `add` | Create entry with frontmatter, security check, reindex | L |
| `search` | Ranked search (tag/title/body scoring + recency + confidence) | L |
| `list` | List entries, optional `--category` filter | S |
| `update` | Open in $EDITOR, re-check security, update timestamps | M |
| `verify` | Update `last_verified` and `verified_by` fields | S |
| `reindex` | Regenerate INDEX.md from all entries | S |
| `stats` | Count by category/confidence, show stale entries | S |
| `link` | Install skill files for Claude Code/Cursor/Codex | M |
| `help` | Usage text | S |

**Key internal functions:**
- `slugify()` — title to kebab-case
- `resolve_collision()` — append `-2`, `-3` if slug exists
- `security_check()` — regex scan for API keys, passwords, connection strings, JWTs, private keys
- `parse_frontmatter()` — extract YAML fields between `---` markers
- `generate_index()` — walk entries/, build pipe-delimited INDEX.md (~50-100 tokens/entry)
- `rank_results()` — composite scoring: tag match (10) > title match (7) > body match (3), recency bonus, confidence multiplier

**Cross-platform (macOS + Linux):**
- `stat`: dual-try helper (`stat -c %Y` || `stat -f %m`)
- `sed -i`: use temp file pattern (`sed ... > tmp && mv tmp orig`)
- Stick to `grep -E` (no `-P`), avoid `readarray`/`mapfile` (bash 3.2 compat)
- `date +%Y-%m-%d` and `date +%s` are portable

**Entry schema (YAML frontmatter):**
```yaml
---
title: "Node Version Issues on M1 Mac"
slug: node-version-m1-mac
category: environment    # environment|debugging|architecture|process|tooling|testing|deployment|security
tags: [node, nvm, m1, mac, arm64]
confidence: high         # high|medium|low
author: Jane Smith
created: 2026-03-18
last_updated: 2026-03-18
last_verified: 2026-03-18
verified_by: Jane Smith
summary: "Node 18+ requires Rosetta-free nvm install on M1 Macs"
---
## Problem
...
## Solution
...
## Context
...
```

**Categories (8):** environment, debugging, architecture, process, tooling, testing, deployment, security

**Search ranking algorithm:**
- Tag match in frontmatter: weight 10
- Title match: weight 7
- Body match: weight 3
- Recency bonus: modified in last 30d → +2, last 90d → +1
- Confidence multiplier: high=1.0, medium=0.7, low=0.4

**Security patterns:**
- `sk-[a-zA-Z0-9]{20,}` (OpenAI/Stripe)
- `AKIA[0-9A-Z]{16}` (AWS)
- `ghp_[a-zA-Z0-9]{36}` (GitHub PAT)
- `password\s*[=:]\s*\S+`
- `token\s*[=:]\s*\S+`
- `mongodb(\+srv)?://[^@]+@`
- `postgres(ql)?://[^@]+@`
- `-----BEGIN .* PRIVATE KEY-----`
- `eyJ[a-zA-Z0-9_-]{10,}\.` (JWT)

### Phase 2: Content and Config
**Files:** `tribal.config.yml`, 5 example entries, `INDEX.md`

Config schema defines: categories list, chat integration settings (Slack/Teams), LLM provider config. Example entries validate the frontmatter schema and provide test data.

### Phase 3: LLM Integration
**Files:** `skills/claude-code.md`, `skills/cursor.md`, `skills/codex.md`, `INSTALL_LLM.md`, `install.sh`

Skill files define **behavioral instructions** for LLM assistants:
1. **When to search:** before investigating errors, when user asks "how do we...", before architectural decisions
2. **When to capture:** after resolving non-trivial bugs, when user shares institutional knowledge, after multi-step troubleshooting
3. **Knowledge lifecycle:** search before creating (avoid dupes), update if entry exists but is stale, set appropriate confidence
4. **Git workflow:** pull --rebase → tribal add → commit → push with retry loop for conflicts

`install.sh` clones to `~/.tribal` and creates a thin wrapper at `~/.local/bin/tribal` with background auto-update (pull if last pull >1h ago).

### Phase 4: Chat Integration
**Files:** `.github/workflows/chat-sync.yml`, `chat-sync/sync.sh`

`sync.sh` (~350 lines):
1. Load config + sync state (`.tribal-sync-state.json`, committed for persistence across ephemeral runners)
2. Fetch messages: Slack via `conversations.history` / Teams via Microsoft Graph API (OAuth2 client credentials)
3. Three modes: channel (dedicated channel), reaction (📚 emoji), auto-scrape (v1 schema only, not implemented)
4. For each message → call LLM API (Anthropic or OpenAI) to extract structured knowledge → `tribal add`
5. Update sync state, commit, push

GitHub Action runs on `schedule: */15 * * * *` and `workflow_dispatch`.

### Phase 5: Tests
**Files:** `tests/test_helper/common-setup.bash`, 12 `.bats` test files

Each test creates a temp `TRIBAL_PATH`, runs `tribal init`, exercises commands, and cleans up. Key coverage:
- `cli_add.bats`: frontmatter generation, slug collision, security filter blocking/bypass, interactive mode
- `cli_search.bats`: tag/title/body ranking, recency/confidence weighting, filters, `--test` exit codes
- `security_filter.bats`: each pattern individually, false positive edge cases
- `integration.bats`: full workflow init→add→search→verify→reindex, pre-commit hook behavior

### Phase 6: Documentation
**Files:** `README.md`, `SPEC.md`

## Dependency Graph

```
Phase 1 (CLI) ──┬──→ Phase 2 (Content) ──→ Phase 5 (Tests)
                ├──→ Phase 3 (LLM Skills)
                ├──→ Phase 4 (Chat Sync)
                └──→ Phase 6 (Docs)
```

## Key Design Decisions

1. **Single bash script CLI** — no dependencies beyond bash, grep, sed, git. Maximizes portability.
2. **INDEX.md regenerated from scratch** on every add/update/reindex — avoids incremental update bugs and merge conflicts (pre-commit hook ensures freshness).
3. **Security check is opt-out** (`--force`) not opt-in — safe by default.
4. **Skill files installed globally** (e.g., `~/.claude/skills/tribal.md`) — works across all projects.
5. **Chat sync state is committed** — persists across ephemeral CI runners.
6. **INDEX.md in `.gitattributes` with `merge=ours`** — prevents rebase conflicts on the auto-generated file.
7. **Background auto-update in wrapper** — `git pull` runs async, takes effect next invocation.

## Estimated Size

| Component | Lines |
|-----------|-------|
| `tribal` CLI | ~700 |
| Pre-commit hook | ~40 |
| Skill files (3) | ~450 |
| `chat-sync/sync.sh` | ~350 |
| GitHub Action | ~80 |
| `install.sh` | ~50 |
| Config + examples | ~350 |
| Test suite | ~600 |
| README + SPEC + INSTALL_LLM | ~400 |
| **Total** | **~3,000** |

## Implementation Order (within each phase)

**Phase 1 internal order:**
1. Utility functions: `slugify`, `die`, `info`, `parse_frontmatter`, `generate_index`, `security_check`
2. `cmd_init`, `cmd_help`, `main()` arg parser
3. `cmd_add` (with security filter, interactive mode, slug collision)
4. `cmd_reindex`
5. `cmd_search` (with ranking)
6. `cmd_list`, `cmd_stats`, `cmd_verify`, `cmd_update`
7. `cmd_link`
8. `.hooks/pre-commit`
9. `.gitignore`, `LICENSE`
