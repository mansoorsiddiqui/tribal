# Tribal Knowledge Base — LLM Bootstrap

This file is optimized for LLM consumption. It tells coding assistants how to use
the tribal knowledge base in this repository.

## What is Tribal?

Tribal is a git-backed knowledge base for team knowledge — the kind of information
that lives in people's heads, Slack threads, or meeting notes. It stores entries as
Markdown files with YAML frontmatter and provides ranked search via a bash CLI.

## Quick Start for LLMs

### 1. Search Before Acting

Before investigating errors, debugging, or proposing solutions:

```bash
tribal search "<keywords>"
```

This returns ranked results. Read the top result's file for the documented solution.

### 2. Capture After Resolving

After resolving a non-trivial issue:

```bash
tribal add \
  --title "Short Searchable Title" \
  --category <environment|debugging|architecture|process|tooling|testing|deployment|security> \
  --tags "tag1,tag2" \
  --confidence <high|medium|low> \
  --summary "One-line description" \
  --body "## Problem\n...\n\n## Solution\n...\n\n## Context\n..."
```

### 3. Update, Don't Duplicate

Always `tribal search` before adding. If an entry exists but is outdated:

```bash
tribal update <slug>
```

### 4. Verify When Confirmed

When you successfully use an entry's solution:

```bash
tribal verify <slug>
```

## Entry Schema

Entries are Markdown files in `entries/` with YAML frontmatter:

```yaml
---
title: "Human-readable title"
slug: kebab-case-filename
category: debugging
tags: [tool, error-code, topic]
confidence: high
author: Name
created: 2026-01-01
last_updated: 2026-01-01
last_verified: 2026-01-01
verified_by: Name
summary: "One sentence for scanning"
---
```

## All Commands

| Command | Description |
|---------|-------------|
| `tribal search <q>` | Ranked search (tag > title > body) |
| `tribal add [opts]` | Add entry (interactive if no flags) |
| `tribal list` | List all entries |
| `tribal update <slug>` | Edit entry in $EDITOR |
| `tribal verify <slug>` | Mark as verified today |
| `tribal reindex` | Rebuild INDEX.md |
| `tribal stats` | Knowledge base statistics |
| `tribal link` | Install LLM skill files |

## INDEX.md

The file `INDEX.md` at the repo root contains a pipe-delimited table of all entries
with path, category, tags, confidence, and summary. It is auto-regenerated on every
add/update/reindex and by the pre-commit hook.
