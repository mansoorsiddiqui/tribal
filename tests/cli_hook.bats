#!/usr/bin/env bats

load test_helper/common-setup

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TRIBAL_PATH="$TEST_TEMP_DIR"
  export TRIBAL_AUTHOR="test-user"
  export ENTRIES_DIR="$TRIBAL_PATH/entries"
  bash "$TRIBAL_PROJECT_DIR/tribal" init "$TRIBAL_PATH" >/dev/null 2>&1

  # Work from a fake project directory
  PROJECT_DIR="$(mktemp -d)"
  cd "$PROJECT_DIR"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR" "$PROJECT_DIR"
}

@test "hook claude creates CLAUDE.md with tribal block" {
  run tribal hook claude
  [ "$status" -eq 0 ]
  [ -f "CLAUDE.md" ]
  grep -q ">>> tribal knowledge base >>>" "CLAUDE.md"
  grep -q "tribal search" "CLAUDE.md"
}

@test "hook cursor creates .cursorrules with tribal block" {
  run tribal hook cursor
  [ "$status" -eq 0 ]
  [ -f ".cursorrules" ]
  grep -q ">>> tribal knowledge base >>>" ".cursorrules"
}

@test "hook codex creates codex.md with tribal block" {
  run tribal hook codex
  [ "$status" -eq 0 ]
  [ -f "codex.md" ]
  grep -q ">>> tribal knowledge base >>>" "codex.md"
}

@test "hook with no args hooks all targets" {
  run tribal hook
  [ "$status" -eq 0 ]
  [ -f "CLAUDE.md" ]
  [ -f ".cursorrules" ]
  [ -f "codex.md" ]
}

@test "hook preserves existing file content" {
  echo "# My Project" > CLAUDE.md
  echo "Some existing rules" >> CLAUDE.md
  run tribal hook claude
  [ "$status" -eq 0 ]
  grep -q "# My Project" "CLAUDE.md"
  grep -q "Some existing rules" "CLAUDE.md"
  grep -q ">>> tribal knowledge base >>>" "CLAUDE.md"
}

@test "hook is idempotent — running twice doesn't duplicate" {
  tribal hook claude
  tribal hook claude
  local count
  count=$(grep -c ">>> tribal knowledge base >>>" "CLAUDE.md")
  [ "$count" -eq 1 ]
}

@test "unhook replaces hook block with opt-out" {
  tribal hook claude
  run tribal unhook claude
  [ "$status" -eq 0 ]
  grep -q "Do NOT use the tribal knowledge base" "CLAUDE.md"
  # Should not have the full instructions anymore
  ! grep -q "Search before debugging" "CLAUDE.md"
}

@test "unhook preserves existing file content" {
  echo "# My Project" > CLAUDE.md
  tribal hook claude
  tribal unhook claude
  grep -q "# My Project" "CLAUDE.md"
  grep -q "Do NOT use" "CLAUDE.md"
}

@test "unhook with no args unhooks all targets" {
  tribal hook
  run tribal unhook
  [ "$status" -eq 0 ]
  grep -q "Do NOT use" "CLAUDE.md"
  grep -q "Do NOT use" ".cursorrules"
  grep -q "Do NOT use" "codex.md"
}

@test "hook after unhook re-enables tribal" {
  tribal hook claude
  tribal unhook claude
  tribal hook claude
  grep -q "Search before debugging" "CLAUDE.md"
  ! grep -q "Do NOT use" "CLAUDE.md"
}
