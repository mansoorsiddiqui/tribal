# Tribal Knowledge Rules

## Knowledge Base Access
You have access to a team knowledge base via the `tribal` CLI.

## Rules

1. BEFORE investigating any error or debugging issue, run: `tribal search "<error keywords>"`
2. BEFORE proposing architectural patterns, run: `tribal search "<pattern name>"`
3. When the user says "how do we..." or "what's our approach to...", search tribal first
4. If tribal search returns results, read the entry and apply the documented solution
5. After resolving a non-trivial issue NOT in the knowledge base, capture it:
   ```
   tribal add --title "Title" --category <cat> --tags "t1,t2" --summary "..." --body "..."
   ```
6. Before adding, always search first to avoid duplicates
7. If an existing entry is outdated, use `tribal update <slug>` instead
8. Categories: environment, debugging, architecture, process, tooling, testing, deployment, security
9. Set confidence to `high` only if verified by multiple people

## Commands Reference
- `tribal search "<query>"` — ranked search
- `tribal add --title "..." ...` — add entry
- `tribal list [--category CAT]` — list entries
- `tribal update <slug>` — edit entry
- `tribal verify <slug>` — mark as verified
- `tribal stats` — knowledge base overview
