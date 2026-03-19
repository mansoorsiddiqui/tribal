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

If `~/.local/bin` is not on the developer's PATH, also add it:

```bash
# Check if already on PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  # Add to shell profile
  SHELL_RC="$HOME/.bashrc"
  [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  export PATH="$HOME/.local/bin:$PATH"
fi
```

Verify it works:

```bash
tribal version
```

## Step 3: Install the skill file for your LLM agent

This is the critical step. The skill file teaches you (the LLM) how to use tribal knowledge automatically during future sessions.

### For Claude Code:

```bash
mkdir -p ~/.claude/skills
cp ~/.tribal/skills/claude-code.md ~/.claude/skills/tribal.md
```

### For Cursor:

```bash
# Install to the user's current project, or global config
cp ~/.tribal/skills/cursor.md .cursorrules
```

### For Codex:

```bash
cp ~/.tribal/skills/codex.md codex.md
```

Or run the built-in command which does all three:

```bash
tribal link --all
```

## Step 4: Verify the installation

Run these commands to confirm everything is working:

```bash
# CLI works
tribal version

# Knowledge base has entries
tribal stats

# Search works
tribal search "example"

# Skill file is installed
ls ~/.claude/skills/tribal.md 2>/dev/null && echo "Claude Code skill: installed"
```

## Step 5: Tell the developer what happened

Report back to the developer:

1. Where the knowledge base was cloned (`~/.tribal`)
2. That the `tribal` CLI is available on their PATH
3. That the skill file was installed (which agent: Claude Code, Cursor, Codex)
4. How many entries are currently in the knowledge base (`tribal stats`)
5. That future sessions will automatically search and contribute to the knowledge base

## What the skill file does

Now that the skill file is installed, in all future coding sessions you will:

- **Search tribal knowledge before debugging**: When you encounter an error, run `tribal search "<error keywords>"` before investigating. If an entry exists, read it and apply the documented solution.
- **Search before proposing patterns**: When asked about team conventions, architecture, or "how do we do X", search first.
- **Capture knowledge after resolving issues**: When you help solve a non-trivial problem (took >3 steps), run `tribal add` to save it for the team.
- **Sync via git**: After adding or updating knowledge, commit and push so the whole team benefits.

You do NOT need to be told to do this. The skill file makes this part of your standard workflow.
