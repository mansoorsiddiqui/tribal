# Tribal Specification

## 1. Purpose

Tribal captures and retrieves institutional ("tribal") knowledge that typically exists only in team members' heads, chat threads, or undocumented conventions. It is designed to be:

1. **Git-native**: All knowledge stored as files in a git repo, using standard git workflows for collaboration
2. **LLM-integrated**: Coding assistants automatically search before acting and capture after resolving
3. **Zero-dependency**: Single bash script, no runtime dependencies beyond bash, grep, sed, git
4. **Chat-aware**: Optional integration to extract knowledge from Slack and Microsoft Teams

## 2. Architecture

```
entries/*.md          ← Knowledge entries (Markdown + YAML frontmatter)
INDEX.md              ← Auto-generated LLM-friendly index table
tribal                ← CLI script (bash)
.hooks/pre-commit     ← Security filter + index freshness
skills/*.md           ← LLM skill/instruction files
chat-sync/sync.sh     ← Chat platform sync engine
tribal.config.yml     ← Configuration
```

### Data Flow

```
User/LLM → tribal add → entries/*.md → generate_index → INDEX.md
                                    ↓
                              pre-commit hook → security_check
                                             → regenerate INDEX.md

Slack/Teams → chat-sync/sync.sh → LLM extraction → tribal add → entries/*.md
```

## 3. Entry Schema

Every knowledge entry is a Markdown file with YAML frontmatter:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | yes | Human-readable, searchable title |
| slug | string | auto | Kebab-case filename (auto-generated from title) |
| category | enum | yes | One of 8 categories (see below) |
| tags | string[] | no | Technology names, error codes, topics |
| confidence | enum | yes | high, medium, or low |
| author | string | auto | From TRIBAL_AUTHOR or git config |
| created | date | auto | YYYY-MM-DD |
| last_updated | date | auto | Updated on edit |
| last_verified | date | auto | Updated on verify |
| verified_by | string | auto | Who verified |
| summary | string | yes | One sentence for scanning/ranking |

### Categories

| Category | Description |
|----------|-------------|
| environment | Local dev setup, tooling versions, OS-specific issues |
| debugging | Error diagnosis, common failures, debugging procedures |
| architecture | Design patterns, system design decisions, conventions |
| process | Team workflows, review policies, branching strategies |
| tooling | Build tools, CI/CD, developer tooling configuration |
| testing | Test patterns, flaky test handling, test infrastructure |
| deployment | Release processes, infrastructure, monitoring |
| security | Security practices, credential management, access control |

## 4. CLI Commands

### tribal init [path]
Creates directory structure, initializes git repo, installs pre-commit hook, generates empty INDEX.md.

### tribal add [options]
Creates a new entry. Flags: `--title`, `--category`, `--tags`, `--confidence`, `--summary`, `--body`, `--force`. Interactive mode if `--title` omitted.

### tribal search \<query\> [options]
Ranked search across all entries. Flags: `--category`, `--tags`, `--test`. Ranking: tag(10) > title(7) > body(3) + recency bonus + confidence multiplier.

### tribal list [--category CAT]
Lists all entries with optional category filter.

### tribal update \<slug\>
Opens entry in $EDITOR, runs security check after edit, updates timestamps.

### tribal verify \<slug\>
Marks entry as verified today by current author.

### tribal reindex
Regenerates INDEX.md from all entries.

### tribal stats
Shows total count, per-category and per-confidence breakdown, stale entries.

### tribal link [--claude|--cursor|--codex|--all]
Installs LLM skill files to appropriate locations.

## 5. Search Ranking Algorithm

For each entry matching the query:

1. **Tag match** (grep against frontmatter tags line): +10
2. **Title match** (grep against frontmatter title): +7
3. **Body match** (grep against content after frontmatter): +3
4. **Recency bonus**: modified within 30 days → +2, within 90 days → +1
5. **Confidence multiplier**: high → x1.0, medium → x0.7, low → x0.4

Results sorted by composite score descending.

## 6. Security Filter

Scans entry content against regex patterns:

| Pattern | Target |
|---------|--------|
| `sk-[a-zA-Z0-9]{20,}` | OpenAI / Stripe keys |
| `AKIA[0-9A-Z]{16}` | AWS access keys |
| `ghp_[a-zA-Z0-9]{36}` | GitHub PATs |
| `password\s*[=:]\s*\S+` | Password assignments |
| `token\s*[=:]\s*\S+` | Token assignments |
| `mongodb(+srv)?://[^@]+@` | MongoDB connection strings |
| `postgres(ql)?://[^@]+@` | PostgreSQL connection strings |
| `-----BEGIN .* PRIVATE KEY-----` | Private keys |
| `eyJ[a-zA-Z0-9_-]{10,}\.` | JWTs |

Enforced by `tribal add` (bypass with `--force`) and the pre-commit hook.

## 7. INDEX.md Format

Auto-generated pipe-delimited Markdown table:

```
# Tribal Knowledge Index

| Path | Category | Tags | Confidence | Summary |
|------|----------|------|------------|---------|
| entries/docker-dns.md | debugging | docker, dns | high | Fix DNS in containers... |
```

Regenerated on: `tribal add`, `tribal update`, `tribal reindex`, and pre-commit hook.

## 8. LLM Skill Behavior

Skill files instruct LLM assistants to:

1. **Always search before acting**: Run `tribal search` before investigating errors, before proposing patterns, when user asks "how do we..."
2. **Capture after resolving**: After non-trivial debugging (>10 min or >3 steps), when user shares institutional knowledge
3. **Update don't duplicate**: Search before adding, use `tribal update` for stale entries
4. **Set appropriate confidence**: high only if verified by multiple people
5. **Handle git concurrency**: pull --rebase before add, retry push on conflict

## 9. Chat Sync

GitHub Action runs every 15 minutes. Two supported platforms (Slack, Teams), three modes:

| Mode | Description |
|------|-------------|
| channel | Monitor dedicated knowledge channel(s) |
| reaction | Watch for specific emoji reaction on any message |
| auto_scrape | (v1 schema only, not implemented) Keyword-based extraction |

Flow: Fetch messages since last sync → Send to LLM for structured extraction → `tribal add` → Commit and push.

## 10. Configuration

`tribal.config.yml` controls: categories list, chat sync settings (platform, channels, mode, LLM provider/model).

Environment variables: `TRIBAL_PATH` (knowledge base location), `TRIBAL_AUTHOR` (author name).
