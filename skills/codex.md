# Tribal Knowledge — Codex Instructions

A team knowledge base is available via the `tribal` CLI tool.

## Workflow

1. Search before debugging: `tribal search "<error or topic>"`
2. Apply documented solutions from search results before trying new approaches
3. After resolving undocumented issues, capture them:
   `tribal add --title "..." --category <cat> --tags "t1,t2" --summary "..." --body "..."`
4. Always search before adding to avoid duplicates
5. Use `tribal update <slug>` for outdated entries instead of creating new ones

## Categories
environment, debugging, architecture, process, tooling, testing, deployment, security

## Commands
- `tribal search "<query>"` — ranked search across knowledge base
- `tribal add` — add new entry (interactive or with flags)
- `tribal list` — list all entries
- `tribal update <slug>` — edit existing entry
- `tribal verify <slug>` — confirm entry is still accurate
- `tribal stats` — knowledge base statistics
