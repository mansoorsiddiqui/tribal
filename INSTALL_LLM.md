# Tribal Knowledge — Installation Instructions

You are an LLM coding agent. A developer has asked you to install their team's tribal knowledge base on their machine. Follow every step below exactly.

## Step 1: Clone the knowledge base

Clone this repository to `~/.tribal`:

```bash
git clone <THIS_REPO_URL> ~/.tribal
```

Replace `<THIS_REPO_URL>` with the URL of the repository where you found this file. If the developer gave you a URL, use that.

Verify it worked:

```bash
ls ~/.tribal/tribal
```

## Step 2: Create the CLI wrapper

Create a wrapper script so `tribal` is available from anywhere:

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/tribal << 'WRAPPER'
#!/usr/bin/env bash
TRIBAL_HOME="${TRIBAL_PATH:-$HOME/.tribal}"

# Auto-update: pull if last pull was >1h ago
LAST_PULL_FILE="$TRIBAL_HOME/.last-pull"
NOW=$(date +%s)
if [ ! -f "$LAST_PULL_FILE" ] || [ $(( NOW - $(cat "$LAST_PULL_FILE" 2>/dev/null || echo 0) )) -gt 3600 ]; then
  (git -C "$TRIBAL_HOME" pull --rebase --quiet 2>/dev/null &)
  echo "$NOW" > "$LAST_PULL_FILE"
fi

export TRIBAL_PATH="$TRIBAL_HOME"
exec bash "$TRIBAL_HOME/tribal" "$@"
WRAPPER

chmod +x ~/.local/bin/tribal
```

If `~/.local/bin` is not on the developer's PATH, add it:

```bash
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  SHELL_RC="$HOME/.bashrc"
  [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  export PATH="$HOME/.local/bin:$PATH"
fi
```

## Step 3: Install global skill files

This is the critical step. Run:

```bash
tribal link --all
```

This installs skill files that teach LLM agents to automatically use tribal knowledge in every session:

- **Claude Code**: `~/.claude/skills/tribal.md` (loaded automatically in every Claude Code session)
- **Cursor**: `~/.cursorrules` (loaded in every Cursor session)
- **Codex**: `~/codex.md`

These are **global** — they apply to every project on this machine. The developer can opt specific projects in or out later with `tribal hook` / `tribal unhook`.

## Step 4: Verify

```bash
tribal version
tribal stats
tribal search "example"
```

## Step 5: Tell the developer

Report back:

1. Knowledge base cloned to `~/.tribal`
2. `tribal` CLI is on their PATH
3. Global skill files installed — tribal knowledge is now active in every LLM coding session
4. Number of entries currently in the knowledge base
5. To reinforce tribal for a specific project: `tribal hook claude` (adds instructions to that project's `CLAUDE.md`)
6. To opt a project out: `tribal unhook claude` (tells the LLM to skip tribal for that repo)

## What happens now

In all future sessions, your global skill file will instruct you to:

- **Search before debugging**: `tribal search "<error>"` before investigating
- **Search before proposing patterns**: check team conventions first
- **Capture after resolving**: `tribal add` when you solve something non-trivial
- **Sync via git**: commit and push so the whole team benefits

This is automatic. You do not need to be told to do this.
