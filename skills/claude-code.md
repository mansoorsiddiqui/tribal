# Tribal Knowledge — Claude Code Skill

You have access to a team knowledge base managed by the `tribal` CLI tool.
The knowledge base is stored at `$TRIBAL_PATH` (default: the current repo or `~/.tribal`).

## When to Search Tribal Knowledge

ALWAYS search tribal knowledge in these situations:

1. **Before investigating any error message**: Run `tribal search "<key terms from error>"`
2. **When the user asks "how do we..." or "what's our pattern for..."**: Search first
3. **When encountering unfamiliar project conventions**: Search for the technology or pattern name
4. **Before proposing architectural decisions**: Check if there's existing guidance
5. **When debugging takes more than 2 steps**: Search for the symptoms

```bash
# Examples
tribal search "connection pool"
tribal search "docker dns"
tribal search "flaky test" --category testing
tribal search "node m1" --tags node
```

If results are found, READ the entry file and apply the documented solution before
trying your own approach.

## When to Capture Knowledge

Capture new tribal knowledge in these situations:

1. **After resolving a non-trivial debugging session** (took >10 minutes or >3 steps)
2. **When the user explicitly shares institutional knowledge** ("we always do X because Y")
3. **When discovering undocumented conventions or gotchas**
4. **After multi-step troubleshooting that others would encounter**
5. **When you find an answer NOT already in the knowledge base**

Before creating a new entry, ALWAYS search first to avoid duplicates:
```bash
tribal search "<topic>"
```

If a related entry exists but is outdated, use `tribal update <slug>` instead of creating a new one.

## How to Capture Knowledge

```bash
tribal add \
  --title "Descriptive, Searchable Title" \
  --category <category> \
  --tags "tag1,tag2,tag3" \
  --confidence medium \
  --summary "One sentence that helps someone decide if this entry is relevant" \
  --body "## Problem
<describe the problem>

## Solution
<describe the solution with code examples>

## Context
<when this applies, caveats, related issues>"
```

Categories: environment, debugging, architecture, process, tooling, testing, deployment, security

### Entry Quality Guidelines

- **Title**: Include key error messages, tool names, or symptoms (searchable)
- **Tags**: Technology names, error codes, team/project names
- **Summary**: Single sentence — would someone scanning a list know if this is relevant?
- **Body**: Always include Problem and Solution sections. Include code examples.
- **Confidence**: Use `high` only if verified by multiple people or well-established. Use `medium` for single-person solutions. Use `low` for workarounds or unverified tips.

## Git Workflow for Knowledge Changes

When adding or updating knowledge, handle git operations:

```bash
cd "$TRIBAL_PATH"
git pull --rebase origin main 2>/dev/null || true
tribal add --title "..." --category "..." --tags "..." --summary "..." --body "..."
git add entries/ INDEX.md
git commit -m "knowledge: <short description>"
# Retry loop for push conflicts
for i in 1 2 3; do
  git push origin main && break
  git pull --rebase origin main
done
```

## Browsing Knowledge

```bash
tribal list                          # List all entries
tribal list --category debugging     # Filter by category
tribal stats                         # Overview of knowledge base
tribal search "query"                # Ranked search
```

## Verifying Knowledge

When you confirm an entry is still accurate (e.g., after using it successfully):
```bash
tribal verify <slug>
```
