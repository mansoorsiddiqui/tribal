#!/usr/bin/env bash
set -euo pipefail

# Tribal Knowledge Base — Installer
# Clones the tribal repo and installs a thin wrapper on PATH

TRIBAL_HOME="${TRIBAL_PATH:-$HOME/.tribal}"
REPO_URL="${TRIBAL_REPO_URL:-}"

# Determine wrapper install location
WRAPPER_PATH=""
for dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
  if [ -d "$dir" ] && [ -w "$dir" ]; then
    WRAPPER_PATH="$dir/tribal"
    break
  fi
done

if [ -z "$WRAPPER_PATH" ]; then
  mkdir -p "$HOME/.local/bin"
  WRAPPER_PATH="$HOME/.local/bin/tribal"
  echo "NOTE: Created ~/.local/bin — ensure it is on your PATH"
fi

echo "Installing tribal to: $TRIBAL_HOME"
echo "Wrapper location: $WRAPPER_PATH"

# Clone if not present
if [ ! -d "$TRIBAL_HOME" ]; then
  if [ -z "$REPO_URL" ]; then
    echo "ERROR: Set TRIBAL_REPO_URL to your tribal knowledge repo URL" >&2
    echo "  Example: TRIBAL_REPO_URL=git@github.com:yourorg/tribal.git bash install.sh" >&2
    exit 1
  fi
  git clone "$REPO_URL" "$TRIBAL_HOME"
  echo "Cloned tribal repo"
else
  echo "Tribal home already exists at $TRIBAL_HOME"
fi

# Create thin wrapper with auto-update
cat > "$WRAPPER_PATH" << 'WRAPPER'
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

chmod +x "$WRAPPER_PATH"

# Initialize if needed
export TRIBAL_PATH="$TRIBAL_HOME"
bash "$TRIBAL_HOME/tribal" init "$TRIBAL_HOME" 2>/dev/null || true

echo ""
echo "Installation complete!"
echo "  Knowledge base: $TRIBAL_HOME"
echo "  CLI wrapper:    $WRAPPER_PATH"
echo ""
echo "Next steps:"
echo "  tribal add --title 'My First Entry'"
echo "  tribal link --all    # Install LLM skill files"
