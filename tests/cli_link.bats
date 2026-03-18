#!/usr/bin/env bats

load test_helper/common-setup

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="test-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"
  export HOME="$TEST_TEMP_DIR/fakehome"
  mkdir -p "$HOME"
  bash "$TRIBAL_PROJECT_DIR/tribal" init "$TRIBAL_PATH" >/dev/null 2>&1

  # Copy skill files to test tribal path
  mkdir -p "$TRIBAL_PATH/skills"
  cp "$TRIBAL_PROJECT_DIR/skills/claude-code.md" "$TRIBAL_PATH/skills/" 2>/dev/null || \
    echo "# test skill" > "$TRIBAL_PATH/skills/claude-code.md"
  cp "$TRIBAL_PROJECT_DIR/skills/cursor.md" "$TRIBAL_PATH/skills/" 2>/dev/null || \
    echo "# test cursor" > "$TRIBAL_PATH/skills/cursor.md"
  cp "$TRIBAL_PROJECT_DIR/skills/codex.md" "$TRIBAL_PATH/skills/" 2>/dev/null || \
    echo "# test codex" > "$TRIBAL_PATH/skills/codex.md"
}

@test "link --claude installs skill file" {
  run tribal link --claude
  [ "$status" -eq 0 ]
  [ -f "$HOME/.claude/skills/tribal.md" ]
}

@test "link --cursor installs rules file" {
  run tribal link --cursor
  [ "$status" -eq 0 ]
  [ -f ".cursorrules" ]
}

@test "link --codex installs config file" {
  run tribal link --codex
  [ "$status" -eq 0 ]
  [ -f "codex.md" ]
}

@test "link with no args installs all" {
  run tribal link
  [ "$status" -eq 0 ]
  [ -f "$HOME/.claude/skills/tribal.md" ]
}
